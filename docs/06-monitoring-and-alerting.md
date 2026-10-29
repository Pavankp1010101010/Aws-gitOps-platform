# Monitoring and alerting

[Back to project overview](../README.md)

## Are Prometheus and Grafana included?

Yes. Both are baseline components, together with Alertmanager, deployed through a pinned kube-prometheus-stack Helm chart after compatibility testing.

- **Prometheus:** scrapes metrics, stores time series, and evaluates alert rules.
- **Grafana:** queries metrics and displays dashboards.
- **Alertmanager:** groups, deduplicates, and routes alerts.
- **Exporters:** expose node and Kubernetes metrics.
- **Application instrumentation:** exposes request counts, errors, and latency histograms.

Grafana dashboards do not themselves establish an alert delivery path.

## Planned dashboards

| Dashboard | Measurements |
|---|---|
| Application | Request rate, error ratio, p95 latency, running version |
| Workloads | Ready replicas, restarts, pending pods, CPU/memory |
| Host | CPU, memory, filesystem space, disk activity |
| Backups | Last successful backup timestamp and job failures |

Request latency must be instrumented with suitable histogram buckets. Avoid high-cardinality labels such as ticket IDs or raw request URLs.

## Planned alerts and verification

| Alert | Test | Expected evidence |
|---|---|---|
| No available application replicas | Deploy a controlled failing version | Notification and deployment status |
| Sustained API errors | Generate a controlled error condition | Error-rate graph and notification |
| Repeated restarts | Trigger a test-only crash scenario | Restart counter and notification |
| Low disk space | Test alert rule safely using synthetic rule input | Rule-test result; do not fill the live disk |
| Backup failure or overdue backup | Force a safe backup failure or simulate stale timestamp | Notification with actionable recovery link |
| EC2 status-check failure | Validate CloudWatch/SNS wiring using supported alarm test methods | External notification path evidence |

Set numeric thresholds, evaluation windows, and recovery behavior before tests. Record actual detection times in the [validation record](08-validation-and-evidence.md).

## Capacity and retention

- Begin with short, explicitly configured metrics retention and bounded storage.
- Size Prometheus and PostgreSQL storage separately.
- Measure peak memory before choosing a cheaper host size.
- Set resource requests and limits using observed behavior.
- Validate K3s-specific scrape targets; do not leave alerts firing for control-plane endpoints that are not exposed in the chosen distribution.

## Known gaps

- All in-cluster monitoring disappears when its only host fails.
- EC2 status checks do not detect every application outage.
- Metrics are not centralized logs. Begin with scoped Kubernetes logs and document their retention limitations.
- Monitoring data is not assumed to survive host destruction unless separately designed.

## Notification destination

Not selected yet. Choose an email or webhook destination during implementation, keep credentials outside Git, and test both firing and resolved notifications.
