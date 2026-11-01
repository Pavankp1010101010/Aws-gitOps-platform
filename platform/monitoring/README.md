# Monitoring configuration

[Platform overview](../README.md) | [Monitoring design](../../docs/06-monitoring-and-alerting.md)

The monitoring stack is managed by Argo CD. A new deployment must perform its own notification and capacity acceptance checks.

## Configuration

- Argo CD installs the pinned `kube-prometheus-stack` chart (`92.16.1`).
- The monitoring Application uses server-side apply so the chart's large CRDs are not rejected by the client-side last-applied annotation size limit.
- Prometheus retains three days of metrics, bounded to 3,500 MB, with a 5 Gi local-path claim. Prometheus, Alertmanager, Grafana, and exporter resources have explicit requests and limits.
- K3s-incompatible control-plane scrapes are disabled. The application ServiceMonitor scrapes `/metrics`; alert rules cover application availability, server errors, p95 latency, and low host disk space.
- The low-disk alert has a `promtool` rule test using synthetic healthy and low-space series; it does not fill or modify the live host filesystem.
- PostgreSQL backup freshness and failure alerts use node-exporter textfile metrics from the host-side systemd service; backup containers do not receive EC2 role credentials.
- Application and host dashboards are checked in. The chart supplies workload dashboards.
- Grafana and Prometheus stay private; Grafana uses a ClusterIP Service and an out-of-band admin Secret.
- Alertmanager sends firing and resolved notifications to a host-side authenticated SNS bridge. The bridge binds only to the K3s host-side address and uses the EC2 role; Alertmanager receives only a generated bearer-token Secret, never AWS credentials.
- `install-sns-webhook.sh` generates the Grafana password and bridge token on the host and creates their Kubernetes Secrets without displaying the values. It has been run through SSM after the narrowly scoped SNS permission was applied.
- The installer uses AWS's official AWS CLI v2 installer when needed; that installer verifies the downloaded CLI package signature.

The bridge publishes to the existing host-alert SNS topic. Its topic ARN is configuration, while email endpoints remain outside the repository. The bridge health endpoint responds successfully.

The current rollout has Grafana, Prometheus, Alertmanager, and the Prometheus Operator running. Alertmanager's chart-generated Watchdog route requires its `null` receiver to remain defined alongside the SNS receiver. CI validates that all rendered route receivers exist.

## Acceptance

Render and validate the Helm and Kustomize output locally and in CI. During deployment, verify known traffic, application metrics, dashboards, alert rules, and both notification paths. The low-disk rule test uses synthetic inputs and does not fill the live host filesystem.

The host bridge is separate from the external CloudWatch/SNS host-status alarm. No monitoring UI is exposed publicly. In-cluster monitoring cannot report an outage of its only host; the existing CloudWatch alarm remains the independent host-status path.
