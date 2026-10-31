import sys
from pathlib import Path


def main():
    if len(sys.argv) != 3:
        raise SystemExit("Usage: extract-prometheus-rules.py <PrometheusRule> <output>")

    source = Path(sys.argv[1]).read_text(encoding="utf-8").splitlines()
    spec_indexes = [index for index, line in enumerate(source) if line == "spec:"]
    if len(spec_indexes) != 1:
        raise SystemExit("Expected exactly one top-level PrometheusRule spec.")

    spec = source[spec_indexes[0] + 1 :]
    if not spec or any(line and not line.startswith("  ") for line in spec):
        raise SystemExit("PrometheusRule spec indentation is invalid.")

    rules = "\n".join(line[2:] if line else "" for line in spec) + "\n"
    if not rules.startswith("groups:\n"):
        raise SystemExit("PrometheusRule spec must contain groups.")

    Path(sys.argv[2]).write_text(rules, encoding="utf-8")


if __name__ == "__main__":
    main()
