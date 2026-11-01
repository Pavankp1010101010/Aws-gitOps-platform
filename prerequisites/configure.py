#!/usr/bin/env python3
"""Render this project's account-specific Terraform and deployment settings."""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = Path(__file__).with_name("project-config.json")


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate_config(config: dict[str, Any]) -> None:
    required = {
        "aws_account_id",
        "aws_region",
        "availability_zone",
        "project_name",
        "instance_type",
        "ami_id",
        "root_volume_gib",
        "state_bucket_name",
        "backup_bucket_name",
        "notification_email",
        "teardown_after_utc",
        "github_repository",
        "github_repository_owner_id",
        "github_repository_id",
        "create_github_oidc_provider",
        "existing_github_oidc_provider_arn",
    }
    _require(set(config) == required, "Configuration keys must exactly match project-config.example.json.")
    string_keys = {
        "aws_account_id",
        "aws_region",
        "availability_zone",
        "project_name",
        "instance_type",
        "ami_id",
        "state_bucket_name",
        "backup_bucket_name",
        "notification_email",
        "teardown_after_utc",
        "github_repository",
        "github_repository_owner_id",
        "github_repository_id",
    }
    _require(
        all(isinstance(config[key], str) for key in string_keys),
        "All textual configuration values must be JSON strings.",
    )
    _require(
        re.fullmatch(r"[0-9]{12}", config["aws_account_id"]) is not None
        and config["aws_account_id"] != "123456789012",
        "Replace aws_account_id with the target 12-digit AWS account ID.",
    )
    _require(
        re.fullmatch(r"[a-z]{2}-[a-z]+-[0-9]+", config["aws_region"]) is not None
        and not config["aws_region"].startswith(("cn-", "us-gov-", "us-iso", "us-isob", "eu-isoe")),
        "aws_region must be a standard AWS commercial region, for example us-east-1.",
    )
    _require(
        re.fullmatch(
            rf"{re.escape(config['aws_region'])}[a-z]",
            config["availability_zone"],
        )
        is not None,
        "availability_zone must be an AZ in aws_region.",
    )
    _require(
        re.fullmatch(r"[a-z][a-z0-9-]{2,31}", config["project_name"]) is not None,
        "project_name must be 3-32 lowercase letters, digits, or hyphens and begin with a letter.",
    )
    _require(
        config["instance_type"] in {"t3.micro", "t3.small", "t3.medium", "t3.large", "m7i-flex.large"},
        "instance_type must be one of t3.micro, t3.small, t3.medium, t3.large, or m7i-flex.large.",
    )
    _require(
        re.fullmatch(r"ami-[0-9a-f]{17}", config["ami_id"]) is not None
        and config["ami_id"] != "ami-00000000000000000",
        "Replace ami_id with a verified Ubuntu 24.04 x86_64 AMI ID for aws_region.",
    )
    _require(
        isinstance(config["root_volume_gib"], int) and 20 <= config["root_volume_gib"] <= 100,
        "root_volume_gib must be an integer from 20 through 100.",
    )
    for key in ("state_bucket_name", "backup_bucket_name"):
        _require(
            re.fullmatch(r"[a-z0-9][a-z0-9-]{1,61}[a-z0-9]", config[key]) is not None
            and not config[key].startswith("replace-with-"),
            f"{key} must be a globally unique, lowercase S3 bucket name.",
        )
    _require(
        config["state_bucket_name"] != config["backup_bucket_name"],
        "state_bucket_name and backup_bucket_name must be different.",
    )
    _require(
        re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", config["notification_email"]) is not None
        and config["notification_email"] != "you@example.com",
        "Replace notification_email with an address you control.",
    )
    _require(
        re.fullmatch(
            r"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z",
            config["teardown_after_utc"],
        )
        is not None,
        "teardown_after_utc must be an RFC3339 UTC timestamp ending in Z.",
    )
    try:
        deadline = datetime.strptime(
            config["teardown_after_utc"], "%Y-%m-%dT%H:%M:%SZ"
        ).replace(tzinfo=timezone.utc)
    except ValueError as error:
        raise ValueError("teardown_after_utc must be a valid RFC3339 UTC timestamp ending in Z.") from error
    _require(deadline > datetime.now(timezone.utc), "teardown_after_utc must be in the future.")
    _require(
        re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", config["github_repository"]) is not None
        and "your-owner/" not in config["github_repository"],
        "github_repository must be the actual GitHub owner/repository slug.",
    )
    for key in ("github_repository_owner_id", "github_repository_id"):
        _require(
            re.fullmatch(r"[0-9]+", config[key]) is not None
            and config[key] not in {"12345678", "123456789"},
            f"Replace {key} with its numeric ID from the GitHub API.",
        )
    _require(
        isinstance(config["create_github_oidc_provider"], bool),
        "create_github_oidc_provider must be true or false.",
    )
    oidc_arn = config["existing_github_oidc_provider_arn"]
    _require(
        (config["create_github_oidc_provider"] and oidc_arn is None)
        or (
            not config["create_github_oidc_provider"]
            and isinstance(oidc_arn, str)
            and re.fullmatch(
                rf"arn:aws:iam::{config['aws_account_id']}:oidc-provider/token.actions.githubusercontent.com",
                oidc_arn,
            )
            is not None
        ),
        "Set exactly one GitHub OIDC option: create the provider after confirming it is absent, or supply the existing provider ARN.",
    )


def _hcl_string(value: str) -> str:
    return json.dumps(value)


def render_tfvars(config: dict[str, Any], *, bootstrap: bool) -> str:
    if bootstrap:
        values: dict[str, Any] = {
            "account_id": config["aws_account_id"],
            "region": config["aws_region"],
            "state_bucket_name": config["state_bucket_name"],
        }
    else:
        values = {
            "account_id": config["aws_account_id"],
            "project_name": config["project_name"],
            "region": config["aws_region"],
            "availability_zone": config["availability_zone"],
            "instance_type": config["instance_type"],
            "ami_id": config["ami_id"],
            "root_volume_gib": config["root_volume_gib"],
            "backup_bucket_name": config["backup_bucket_name"],
            "notification_email": config["notification_email"],
            "teardown_after_utc": config["teardown_after_utc"],
            "create_github_oidc_provider": config["create_github_oidc_provider"],
            "existing_github_oidc_provider_arn": config["existing_github_oidc_provider_arn"],
            "github_repository": config["github_repository"],
            "github_repository_owner_id": config["github_repository_owner_id"],
            "github_repository_id": config["github_repository_id"],
        }

    lines = []
    for key, value in values.items():
        if isinstance(value, str):
            rendered = _hcl_string(value)
        elif value is None:
            rendered = "null"
        elif isinstance(value, bool):
            rendered = str(value).lower()
        else:
            rendered = str(value)
        lines.append(f"{key} = {rendered}")
    return "\n".join(lines) + "\n"


def _replace_one(path: str, text: str, pattern: str, replacement: str) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.MULTILINE)
    if count != 1:
        raise ValueError(f"Expected one configurable setting in {path}, found {count}.")
    return updated


def render_project_files(config: dict[str, Any], root: Path) -> dict[Path, str]:
    repo_url = f"https://github.com/{config['github_repository']}.git"
    ecr_url = (
        f"{config['aws_account_id']}.dkr.ecr.{config['aws_region']}.amazonaws.com/"
        f"{config['project_name']}-support-ticket"
    )
    files = {
        "platform/kubernetes/root-app.yaml": (
            r"^    repoURL: (?:__GITHUB_REPOSITORY_URL__|https://github\.com/.*)$",
            f"    repoURL: {repo_url}",
        ),
        "platform/kubernetes/cluster/support-ticket-app.yaml": (
            r"^    repoURL: (?:__GITHUB_REPOSITORY_URL__|https://github\.com/.*)$",
            f"    repoURL: {repo_url}",
        ),
        "platform/kubernetes/cluster/monitoring-app.yaml": (
            r"^    - repoURL: (?:__GITHUB_REPOSITORY_URL__|https://github\.com/.*)$",
            f"    - repoURL: {repo_url}",
        ),
        "platform/kubernetes/charts/support-ticket/values.yaml": (r"^  repository: .*", f"  repository: {ecr_url}"),
        "platform/bootstrap/bootstrap.sh": (r'^readonly REGION="[^"]+"$', f'readonly REGION="{config["aws_region"]}"'),
        "platform/backup/install-postgres-backup.sh": (
            r"^(printf 'BACKUP_BUCKET=%s\\nAWS_DEFAULT_REGION=)[^\\\r\n]+",
            rf"\g<1>{config['aws_region']}",
        ),
        "platform/backup/backup-postgres.sh": (
            r'^(export AWS_DEFAULT_REGION="\$\{AWS_DEFAULT_REGION:-)[^}]+(}")$',
            rf"\g<1>{config['aws_region']}\g<2>",
        ),
        "platform/backup/deploy-postgres-backup.ps1": (
            r"^  \[string\]\$Region = '[^']+'$",
            f"  [string]$Region = '{config['aws_region']}'",
        ),
    }
    rendered: dict[Path, str] = {}
    for relative_path, (pattern, replacement) in files.items():
        text = (root / relative_path).read_text(encoding="utf-8")
        rendered[Path(relative_path)] = _replace_one(relative_path, text, pattern, replacement)

    ps_path = Path("platform/backup/deploy-postgres-backup.ps1")
    ps_text = rendered[ps_path]
    ps_text = _replace_one(
        str(ps_path),
        ps_text,
        r"^if \(\$LASTEXITCODE -ne 0 -or \$accountId -ne '[^']+'\) \{$",
        f"if ($LASTEXITCODE -ne 0 -or $accountId -ne '{config['aws_account_id']}') {{",
    )
    ps_text = _replace_one(
        str(ps_path),
        ps_text,
        r"^      if \(\$candidate\.State\.Name -eq 'running' -and \$nameTag\.Value -eq '[^']+'\) \{$",
        f"      if ($candidate.State.Name -eq 'running' -and $nameTag.Value -eq '{config['project_name']}-k3s') {{",
    )
    rendered[ps_path] = ps_text

    sns_path = Path("platform/monitoring/install-sns-webhook.sh")
    sns_text = (root / sns_path).read_text(encoding="utf-8")
    sns_text = _replace_one(
        str(sns_path),
        sns_text,
        r"^AWS_DEFAULT_REGION=.*$",
        f"AWS_DEFAULT_REGION={config['aws_region']}",
    )
    sns_text = _replace_one(
        str(sns_path),
        sns_text,
        r"^SNS_TOPIC_ARN=.*$",
        f"SNS_TOPIC_ARN=arn:aws:sns:{config['aws_region']}:{config['aws_account_id']}:{config['project_name']}-host-alerts",
    )
    rendered[sns_path] = sns_text
    return rendered


def configure(config: dict[str, Any], root: Path) -> None:
    validate_config(config)
    rendered_files = render_project_files(config, root)
    generated_files = {
        Path("platform/terraform/bootstrap/terraform.tfvars"): render_tfvars(config, bootstrap=True),
        Path("platform/terraform/environment/terraform.tfvars"): render_tfvars(config, bootstrap=False),
        Path("platform/terraform/environment/backend.hcl"): (
            f'bucket = {_hcl_string(config["state_bucket_name"])}\n'
            f'region = {_hcl_string(config["aws_region"])}\n'
            f'key = "{config["project_name"]}/demo/terraform.tfstate"\n'
            "encrypt = true\n"
            "use_lockfile = true\n"
        ),
    }
    for relative_path, contents in {**rendered_files, **generated_files}.items():
        destination = root / relative_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(contents, encoding="utf-8", newline="\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=CONFIG_PATH, help="Path to the private project-config.json.")
    args = parser.parse_args()
    try:
        config = json.loads(args.config.read_text(encoding="utf-8"))
        if not isinstance(config, dict):
            raise ValueError("The configuration file must contain a JSON object.")
        configure(config, ROOT)
    except (OSError, json.JSONDecodeError, ValueError) as error:
        print(f"Configuration failed: {error}", file=sys.stderr)
        return 1

    print("Rendered project-specific Terraform inputs, backend settings, manifests, and install scripts.")
    print("Next: inspect git diff, follow prerequisites/README.md, and set the documented GitHub Actions variables.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
