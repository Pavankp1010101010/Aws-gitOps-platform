# Stage 07 - Monitoring and notifications

[Stage index](README.md) | [Previous](06-end-to-end-gitops.md) | [Next](08-reliability-and-recovery.md)

Status: Not started.

## Entry conditions

Stage 06 deployment and application smoke checks pass.

## Goal

Make failures visible and verify that notifications reach an operator.

## Work checklist

- [ ] Deploy compatible pinned kube-prometheus-stack through GitOps.
- [ ] Configure bounded retention, storage, and resource requests/limits.
- [ ] Scrape application metrics and supported K3s/node targets.
- [ ] Add Grafana application, host, and workload dashboards.
- [ ] Set explicit alert thresholds/windows and route through Alertmanager.
- [ ] Keep monitoring interfaces private.
- [ ] Validate external CloudWatch/SNS host notifications separately.
- [ ] Add backup freshness/job monitoring when backup jobs are introduced in Stage 08.

## Work location

[Monitoring directory](../platform/monitoring/README.md), with external host alarm resources in Terraform.

## Exit checks

- [ ] Known request traffic appears as rate, errors, and p95 latency.
- [ ] Controlled failure produces a received firing and resolved notification.
- [ ] Safe rule tests cover low-space alerts without filling a live disk.
- [ ] K3s compatibility issues do not leave irrelevant alerts permanently firing.
- [ ] External host notification path is tested and its coverage limitations documented.
- [ ] Actual monitoring resource use fits the selected host.

Record MON-01 and MON-02 results, notification timings, and redacted dashboards.

## Cost and approval gate

Review alert usefulness and capacity before Stage 08. Do not equate monitoring on one host with independent application availability monitoring.
