#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 2 || ! -f "$1" || ! -f "$2" ]]; then
  echo "Usage: $0 <rendered-monitoring-chart> <rendered-monitoring-gitops>" >&2
  exit 2
fi

chart_manifest="$1"
gitops_manifest="$2"

! grep -Eq '^  type: (LoadBalancer|NodePort)$' "$chart_manifest" || {
  echo "Monitoring Services must not be externally exposed." >&2
  exit 1
}
! grep -q '^kind: Ingress$' "$chart_manifest" || {
  echo "Monitoring must not create an Ingress." >&2
  exit 1
}
grep -q 'monitoring-grafana-admin' "$chart_manifest" || {
  echo "Grafana must reference its out-of-band admin Secret." >&2
  exit 1
}
grep -Eq 'retention: "?3d"?$' "$chart_manifest" || {
  echo "Prometheus retention must remain explicitly bounded." >&2
  exit 1
}
python3 - "$chart_manifest" <<'PY'
import base64
import re
import sys

manifest = open(sys.argv[1], encoding="utf-8").read()
alertmanager_config = None
for document in re.split(r"(?m)^---\s*$", manifest):
    if not re.search(r"(?m)^kind: Secret\s*$", document):
        continue
    name = re.search(r"(?m)^  name: (.+)$", document)
    if not name or "alertmanager" not in name.group(1):
        continue
    value = re.search(r"(?m)^  alertmanager\.yaml:\s*['\"]?([A-Za-z0-9+/=]+)", document)
    if value:
        alertmanager_config = base64.b64decode(value.group(1), validate=True).decode("utf-8")
        break

if not alertmanager_config:
    sys.exit("Rendered Alertmanager configuration Secret is missing.")
if "/etc/alertmanager/secrets/monitoring-sns-webhook/token" not in alertmanager_config:
    sys.exit("Alertmanager must use the mounted, out-of-band SNS webhook token.")
if "send_resolved: true" not in alertmanager_config:
    sys.exit("Alertmanager must send resolved notifications.")

defined_receivers = set(
    re.findall(r"""(?m)^\s*-\s+name:\s*["']?([^"'\s]+)""", alertmanager_config)
)
route_receivers = set(
    re.findall(r"""(?m)^\s*receiver:\s*["']?([^"'\s]+)""", alertmanager_config)
)
undefined_receivers = route_receivers - defined_receivers
if undefined_receivers:
    sys.exit(
        "Alertmanager routes reference undefined receivers: "
        + ", ".join(sorted(undefined_receivers))
        + "."
    )
PY
! grep -q 'adminPassword:' platform/monitoring/values.yaml || {
  echo "Grafana credentials must not be stored in Helm values." >&2
  exit 1
}
grep -q '^kind: ServiceMonitor$' "$gitops_manifest" || {
  echo "The application ServiceMonitor is missing." >&2
  exit 1
}
grep -q '^kind: PrometheusRule$' "$gitops_manifest" || {
  echo "The application and host alert rules are missing." >&2
  exit 1
}
grep -q 'path: /metrics' "$gitops_manifest" || {
  echo "The ServiceMonitor must scrape the application metrics endpoint." >&2
  exit 1
}
grep -q 'grafana_dashboard: "1"' "$gitops_manifest" || {
  echo "Grafana dashboard ConfigMaps must be discoverable by the sidecar." >&2
  exit 1
}

echo "Monitoring chart and GitOps output passed private-access, bounded-retention, secret-reference, and scrape checks."
