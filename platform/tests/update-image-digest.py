#!/usr/bin/env python3
import re
import sys
from pathlib import Path


DIGEST_PATTERN = re.compile(r"sha256:[0-9a-f]{64}")
COMMIT_PATTERN = re.compile(r"[0-9a-f]{40}")


def update_image_values(path: Path, digest: str, source_commit: str) -> None:
    if not DIGEST_PATTERN.fullmatch(digest):
        raise ValueError("Image digest must be a sha256 digest.")
    if not COMMIT_PATTERN.fullmatch(source_commit):
        raise ValueError("Source commit must be a full lowercase Git SHA.")

    lines = path.read_text(encoding="utf-8").splitlines()
    image_sections = [index for index, line in enumerate(lines) if line == "image:"]
    if len(image_sections) != 1:
        raise ValueError(f"Expected one top-level image section in {path}, found {len(image_sections)}.")

    start = image_sections[0] + 1
    end = next(
        (index for index in range(start, len(lines)) if lines[index] and not lines[index][0].isspace()),
        len(lines),
    )
    replacements = {"digest": digest, "sourceCommit": source_commit}
    for key, value in replacements.items():
        matching = [index for index in range(start, end) if lines[index].startswith(f"  {key}: ")]
        if len(matching) != 1:
            raise ValueError(f"Expected exactly one image.{key} value in {path}, found {len(matching)}.")
        lines[matching[0]] = f"  {key}: {value}"

    path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit(f"Usage: {sys.argv[0]} <values.yaml> <image-digest> <source-commit>")
    try:
        update_image_values(Path(sys.argv[1]), sys.argv[2], sys.argv[3])
    except (OSError, ValueError) as error:
        raise SystemExit(str(error)) from error
