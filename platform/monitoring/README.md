# Monitoring configuration

[Platform overview](../README.md) | [Monitoring design](../../docs/06-monitoring-and-alerting.md)

Status: the core stack and notification acceptance checks are verified; sustained-load capacity was not measured.

## Configuration

- Argo CD installs the pinned `kube-prometheus-stack` chart (`92.16.1`).
- The monitoring Application uses server-side apply so the chart's large CRDs are not rejected by the client-side last-applied annotation size limit.
- Prometheus retains three days of metrics, bounded to 3,500 MB, with a 5 Gi local-path claim. Prometheus, Alertmanager, Grafana, and exporter resources have explicit requests and limits.
- K3s-incompatible control-plane scrapes are disabled. The application ServiceMonitor scrapes `/metrics`; alert rules cover application availability, server errors, p95 latency, and low host disk space.
- The low-disk alert has a `promtool` rule test using synthetic healthy and low-space series; it does not fill or modify the live host filesystem.
- Stage 08 adds PostgreSQL backup freshness and failure alerts using node-exporter textfile metrics from the host-side systemd service; backup containers do not receive EC2 role credentials.
- Application and host dashboards are checked in. The chart supplies workload dashboards.
- Grafana and Prometheus stay private; Grafana uses a ClusterIP Service and an out-of-band admin Secret.
- Alertmanager sends firing and resolved notifications to a host-side authenticated SNS bridge. The bridge binds only to the K3s host-side address and uses the EC2 role; Alertmanager receives only a generated bearer-token Secret, never AWS credentials.
- `install-sns-webhook.sh` generates the Grafana password and bridge token on the host and creates their Kubernetes Secrets without displaying the values. It has been run through SSM after the narrowly scoped SNS permission was applied.
- The installer uses AWS's official AWS CLI v2 installer when needed; that installer verifies the downloaded CLI package signature.

The bridge publishes to the existing host-alert SNS topic. Its topic ARN is configuration, while email endpoints remain outside the repository. The bridge health endpoint responds successfully.

The current rollout has Grafana, Prometheus, Alertmanager, and the Prometheus Operator running. Alertmanager's chart-generated Watchdog route requires its `null` receiver to remain defined alongside the SNS receiver. CI validates that all rendered route receivers exist.

On 2026-10-31, Argo reported the monitoring Application `Synced / Healthy` at merged revision `8c35ee0`, and all monitoring pods were ready. Prometheus scraped the application target (`up=1`) and recorded controlled `/health/live` traffic with a measured p95 of about 4.75 ms. Grafana's admin password was reconciled with its out-of-band Secret; the authenticated API confirmed the Support Ticket Application and Kubernetes Host dashboards, and its Prometheus data-source query returned positive application request-rate data. A point-in-time host snapshot showed 132 millicores CPU (6%), 3,907 MiB memory (50%), and 32% root-volume use; monitoring pods used about 854 MiB combined. A synthetic firing/resolved pair reached Alertmanager, and its webhook attempt count increased without a corresponding increase in failures after the bridge AWS CLI permissions were restricted to the service group. The operator confirmed receipt of both the Alertmanager firing/resolved pair and the separate CloudWatch alarm/OK pair. These resource figures are snapshots only; sustained-load capacity and delivery latency were not measured.

## Acceptance

Render and validate the Helm and Kustomize output locally and in CI. The merged stack is deployed through Argo CD; known traffic, application metrics, dashboards, and both notification paths have been verified, and the low-disk rule test uses synthetic inputs. The operator confirmed receipt of both notification pairs; capacity evidence is point-in-time only, with no sustained-load claim. See [Stage 07](../../stages/07-monitoring.md).

The host bridge is separate from the external CloudWatch/SNS host-status alarm. No monitoring UI is exposed publicly. In-cluster monitoring cannot report an outage of its only host; the existing CloudWatch alarm remains the independent host-status path.
