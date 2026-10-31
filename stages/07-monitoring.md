# Stage 07 - Monitoring and notifications

[Stage index](README.md) | [Previous](06-end-to-end-gitops.md) | [Next](08-reliability-and-recovery.md)

Status: Acceptance checks pass; installer hardening and final evidence are in the pushed branch awaiting PR merge. Sustained-load capacity was not measured.
Status: Complete. Monitoring, notification, and point-in-time resource checks pass; sustained-load capacity was not measured.

## Entry conditions

Stage 06 deployment and application smoke checks pass.

## Goal

Make failures visible and verify that notifications reach an operator.

## Work checklist

- [x] Deploy compatible pinned kube-prometheus-stack through GitOps.
- [x] Configure bounded retention, storage, and resource requests/limits.
- [x] Scrape application metrics and supported K3s/node targets.
- [x] Add Grafana application, host, and workload dashboards.
- [x] Set explicit alert thresholds/windows and route through Alertmanager.
- [x] Keep monitoring interfaces private.
- [x] Validate external CloudWatch/SNS host notifications separately through alarm-history SNS action results.
- [ ] Add backup freshness/job monitoring when backup jobs are introduced in Stage 08.

## Work location

[Monitoring directory](../platform/monitoring/README.md), with external host alarm resources in Terraform.

## Exit checks

- [x] Known request traffic appears as rate, errors, and p95 latency in Prometheus; Grafana's Prometheus data-source query returns positive application request-rate data.
- [x] Controlled Alertmanager firing/resolved and CloudWatch ALARM/OK notifications were received by the operator.
- [x] Safe rule tests cover low-space alerts without filling a live disk.
- [x] K3s compatibility issues do not leave irrelevant alerts permanently firing.
- [x] External host notification path is tested and its coverage limitations documented; it checks host status, not independent application availability.
- [x] Point-in-time node, pod, and disk resource use is recorded; sustained-load capacity is explicitly not measured.

Record MON-01 and MON-02 results and redacted dashboards; no delivery-latency measurement is claimed.

## Cost and approval gate

Review alert usefulness and capacity before Stage 08. Do not equate monitoring on one host with independent application availability monitoring.

## Current implementation

The pinned `kube-prometheus-stack` chart and monitoring manifests are under `platform/monitoring`. Grafana and Prometheus remain private. Alertmanager calls a host-side bridge bound only to the K3s bridge address; the bridge publishes to the existing SNS topic using a topic-scoped EC2-role permission. The bridge token and Grafana password are generated on the host and stored in Kubernetes Secrets out of band.

The scoped SNS permission and bridge are deployed; the bridge health endpoint responds successfully. The chart-default Watchdog route initially referenced a `null` receiver that was missing from the custom receiver list; the merged monitoring values and CI guard now define and validate it. The generated webhook CA bundle was applied to the admission configuration to restore operator trust. A controlled firing/resolved pair is now accepted by SNS, and there were no additional webhook failures after restricting AWS CLI installation access to the bridge service group.

### Live rollout evidence - 2026-10-31

- Argo monitoring Application: `Synced / Healthy` at merged revision `8c35ee0`; Prometheus, Alertmanager, Grafana, operator, kube-state-metrics, and node exporter pods are ready.
- Prometheus reports the support-ticket application target `up=1`. Eight controlled `GET /health/live` requests returned 2xx; the scraped request counter reached 397, the observed two-minute request rate was about 0.156 requests/second, and the five-minute p95 for that route was about 4.75 ms.
- After reconciling its persisted admin password with the out-of-band Secret, the authenticated Grafana API listed the Support Ticket Application and Kubernetes Host dashboards. A Grafana Prometheus data-source query returned positive support-ticket request-rate data.
- A `kubectl top` snapshot showed the node at 132 millicores (6%) and 3,907 MiB memory (50%). Monitoring pods used approximately 854 MiB combined: Grafana 394 MiB, Prometheus 389 MiB, Alertmanager 24 MiB, operator 21 MiB, kube-state-metrics 17 MiB, and node exporter 9 MiB.
- Root volume usage was 8.8 GiB of 29 GiB (32%). These are point-in-time measurements, not sustained peak capacity results.
- A controlled Alertmanager firing/resolved pair was accepted by SNS. A separate CloudWatch `OK -> ALARM -> OK` test recorded successful SNS actions for both transitions. The operator confirmed receipt of both test pairs. One SNS email subscription is confirmed and another is pending.

Argo health, application metric queries, dashboard access, both notification paths, and point-in-time resource recording are verified. Sustained-load capacity and delivery latency are not claimed. Complete this stage after merging the pushed installer hardening and evidence update; keep the existing host cleanup deadline in view.
Argo health, application metric queries, dashboard access, both notification paths, and point-in-time resource recording are verified. Sustained-load capacity and delivery latency are not claimed. Keep the existing host cleanup deadline in view.

Local Prometheus v3.5.0 `promtool` tests pass for missing application targets and the low-disk alert's timing, using synthetic inputs without changing the host filesystem.
