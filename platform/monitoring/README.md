# Monitoring configuration

[Platform overview](../README.md) | [Monitoring design](../../docs/06-monitoring-and-alerting.md)

Status: planned. No Helm values, dashboard JSON, alert rules, or notification configuration exist.

## Future contents

- Pinned kube-prometheus-stack chart configuration.
- K3s-compatible scrape configuration.
- Application ServiceMonitor or equivalent scrape discovery.
- Application, workload, host, and backup dashboards.
- Tested Prometheus alert rules.
- Alertmanager notification routing with external secret references.
- Retention, storage, and resource settings.

## Acceptance

Generate known traffic, confirm metric values, trigger controlled failures, and verify received firing/resolved notifications.

The external CloudWatch/SNS host alarm belongs to Terraform infrastructure, not this in-cluster monitoring chart.
