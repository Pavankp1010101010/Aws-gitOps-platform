import json
import tempfile
import unittest
from pathlib import Path

import configure


class ConfigureTests(unittest.TestCase):
    def setUp(self) -> None:
        self.config = json.loads(
            (Path(__file__).with_name("project-config.example.json")).read_text(encoding="utf-8")
        )
        self.config.update(
            {
                "aws_account_id": "555555555555",
                "ami_id": "ami-0123456789abcdef0",
                "state_bucket_name": "synthetic-project-state-12345",
                "backup_bucket_name": "synthetic-project-backups-12345",
                "notification_email": "synthetic@example.invalid",
                "github_repository": "synthetic-owner/synthetic-repository",
                "github_repository_owner_id": "55512345",
                "github_repository_id": "555123456",
            }
        )

    def test_config_generates_scoped_inputs_and_rendered_manifests(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            for relative_path in (
                "platform/kubernetes/root-app.yaml",
                "platform/kubernetes/cluster/support-ticket-app.yaml",
                "platform/kubernetes/cluster/monitoring-app.yaml",
                "platform/kubernetes/charts/support-ticket/values.yaml",
                "platform/bootstrap/bootstrap.sh",
                "platform/backup/install-postgres-backup.sh",
                "platform/backup/backup-postgres.sh",
                "platform/backup/deploy-postgres-backup.ps1",
                "platform/monitoring/install-sns-webhook.sh",
            ):
                source = configure.ROOT / relative_path
                destination = root / relative_path
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_text(source.read_text(encoding="utf-8"), encoding="utf-8")

            configure.configure(self.config, root)

            root_manifest = (root / "platform/kubernetes/root-app.yaml").read_text(encoding="utf-8")
            child_manifest = (root / "platform/kubernetes/cluster/monitoring-app.yaml").read_text(
                encoding="utf-8"
            )
            chart_values = (
                root / "platform/kubernetes/charts/support-ticket/values.yaml"
            ).read_text(encoding="utf-8")
            environment_tfvars = (
                root / "platform/terraform/environment/terraform.tfvars"
            ).read_text(encoding="utf-8")
            backend = (root / "platform/terraform/environment/backend.hcl").read_text(
                encoding="utf-8"
            )
            backup_installer = (
                root / "platform/backup/install-postgres-backup.sh"
            ).read_text(encoding="utf-8")
            backup_deployer = (
                root / "platform/backup/deploy-postgres-backup.ps1"
            ).read_text(encoding="utf-8")
            sns_installer = (
                root / "platform/monitoring/install-sns-webhook.sh"
            ).read_text(encoding="utf-8")

            self.assertIn("https://github.com/synthetic-owner/synthetic-repository.git", root_manifest)
            self.assertIn("https://github.com/synthetic-owner/synthetic-repository.git", child_manifest)
            self.assertIn(
                "555555555555.dkr.ecr.us-east-1.amazonaws.com/ticket-platform-support-ticket",
                chart_values,
            )
            self.assertIn('github_repository_owner_id = "55512345"', environment_tfvars)
            self.assertIn('bucket = "synthetic-project-state-12345"', backend)
            self.assertIn('key = "ticket-platform/demo/terraform.tfstate"', backend)
            self.assertIn("AWS_DEFAULT_REGION=us-east-1", backup_installer)
            self.assertIn("$accountId -ne '555555555555'", backup_deployer)
            self.assertIn("$nameTag.Value -eq 'ticket-platform-k3s'", backup_deployer)
            self.assertIn(
                "SNS_TOPIC_ARN=arn:aws:sns:us-east-1:555555555555:ticket-platform-host-alerts",
                sns_installer,
            )
            self.assertNotIn("__", root_manifest + child_manifest + chart_values)

    def test_configuration_can_be_retargeted(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            for relative_path in (
                "platform/kubernetes/root-app.yaml",
                "platform/kubernetes/cluster/support-ticket-app.yaml",
                "platform/kubernetes/cluster/monitoring-app.yaml",
                "platform/kubernetes/charts/support-ticket/values.yaml",
                "platform/bootstrap/bootstrap.sh",
                "platform/backup/install-postgres-backup.sh",
                "platform/backup/backup-postgres.sh",
                "platform/backup/deploy-postgres-backup.ps1",
                "platform/monitoring/install-sns-webhook.sh",
            ):
                source = configure.ROOT / relative_path
                destination = root / relative_path
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_text(source.read_text(encoding="utf-8"), encoding="utf-8")

            configure.configure(self.config, root)
            second_config = {
                **self.config,
                "aws_account_id": "666666666666",
                "aws_region": "ap-south-1",
                "availability_zone": "ap-south-1b",
                "project_name": "next-platform",
                "github_repository": "next-owner/next-repository",
                "github_repository_owner_id": "66612345",
                "github_repository_id": "666123456",
            }
            configure.configure(second_config, root)

            root_manifest = (root / "platform/kubernetes/root-app.yaml").read_text(
                encoding="utf-8"
            )
            chart_values = (
                root / "platform/kubernetes/charts/support-ticket/values.yaml"
            ).read_text(encoding="utf-8")
            sns_installer = (
                root / "platform/monitoring/install-sns-webhook.sh"
            ).read_text(encoding="utf-8")
            backend = (root / "platform/terraform/environment/backend.hcl").read_text(
                encoding="utf-8"
            )

            self.assertIn("https://github.com/next-owner/next-repository.git", root_manifest)
            self.assertIn(
                "666666666666.dkr.ecr.ap-south-1.amazonaws.com/next-platform-support-ticket",
                chart_values,
            )
            self.assertIn(
                "SNS_TOPIC_ARN=arn:aws:sns:ap-south-1:666666666666:next-platform-host-alerts",
                sns_installer,
            )
            self.assertIn('key = "next-platform/demo/terraform.tfstate"', backend)

    def test_rejects_mismatched_github_oidc_options(self) -> None:
        self.config["existing_github_oidc_provider_arn"] = (
            "arn:aws:iam::555555555555:oidc-provider/token.actions.githubusercontent.com"
        )
        with self.assertRaisesRegex(ValueError, "Set exactly one GitHub OIDC option"):
            configure.validate_config(self.config)

    def test_rejects_availability_zone_from_another_region(self) -> None:
        self.config["availability_zone"] = "us-west-2a"
        with self.assertRaisesRegex(ValueError, "availability_zone"):
            configure.validate_config(self.config)

    def test_rejects_the_same_state_and_backup_bucket(self) -> None:
        self.config["backup_bucket_name"] = self.config["state_bucket_name"]
        with self.assertRaisesRegex(ValueError, "must be different"):
            configure.validate_config(self.config)


if __name__ == "__main__":
    unittest.main()
