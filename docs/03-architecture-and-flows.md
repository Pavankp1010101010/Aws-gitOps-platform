# Architecture and flows

[Project overview](../README.md) | [Deployment guide](../prerequisites/README.md)

These diagrams describe the current repository configuration. They are not a claim that an AWS environment is presently deployed.

## Platform components and trust boundaries

```mermaid
flowchart LR
    Dev[Developer] -->|reviewed source changes| GitHub[Public GitHub repository]
    GitHub -->|CI and release workflows| Actions[GitHub Actions]
    Actions -->|GitHub OIDC, short-lived role| Publisher[IAM image-publisher role]
    Actions -->|tested, scanned, immutable image| ECR[Amazon ECR]
    Actions -->|propose digest update| DeployPR[GitOps deployment pull request]
    DeployPR -->|review and merge| GitHub

    subgraph AWS["AWS account and selected commercial region"]
        subgraph VPC["Project VPC: public subnet; no inbound security-group rules"]
            EC2[Ubuntu EC2 host]
            subgraph K3s["Single-node K3s"]
                Argo[Argo CD]
                AppSvc[Application ClusterIP Service]
                App[Support-ticket application pod]
                DbSvc[PostgreSQL ClusterIP Service]
                DB[PostgreSQL StatefulSet]
                PVC[PersistentVolumeClaim]
                Prom[Prometheus]
                Grafana[Grafana]
                Alertmanager[Alertmanager]
                Bridge[SNS webhook bridge]
                Argo -->|reconcile manifests| AppSvc
                AppSvc --> App
                App --> DbSvc --> DB --> PVC
                Prom -->|scrape /metrics and exporters| App
                Grafana -->|query| Prom
                Prom -->|alert rules| Alertmanager -->|authenticated internal webhook| Bridge
            end
            EC2 --- K3s
            EC2 -->|instance role, least privilege| Backup[S3 backup bucket]
            EC2 -->|status checks| CW[CloudWatch alarm]
            CW --> SNS[SNS email notification]
            Bridge -->|instance role, scoped publish| SNS
        end
        ECR -->|private image pull using host role| App
        GitHub -->|HTTPS desired state| Argo
        SSM[AWS Systems Manager] <-->|outbound agent session| EC2
    end

    Operator[Operator workstation] -->|SSM session and local port-forward| SSM
```

## Network and administration flow

```mermaid
flowchart TB
    Operator[Authorized operator workstation]
    SSMAPI[AWS Systems Manager APIs]
    Internet[Internet gateway]

    subgraph AWS["AWS account"]
        subgraph VPC["Project VPC"]
            SG["Security group: outbound only"]
            Host["EC2 host with public IPv4"]
            K3s["K3s ClusterIP services"]
            Host --> K3s
            SG -. attached to .-> Host
            Host -->|outbound HTTPS for SSM, packages, GitHub, ECR, and S3| Internet
        end
    end

    Operator -->|authenticated session request| SSMAPI
    SSMAPI <-->|agent-initiated outbound control channel| Host
    Operator -.->|encrypted SSM port-forward tunnel| Host
    Host -->|local kubectl port-forward| K3s
    Internet -->|no direct inbound application path| SG
```

The EC2 public address supports outbound connectivity; it does not create a public application endpoint. Do not add inbound rules, NodePorts, or public load balancers to bypass the documented private access path.

## User request path

```mermaid
sequenceDiagram
    actor User as Authorized operator
    participant Browser as Browser on workstation
    participant SSM as Systems Manager tunnel
    participant Host as EC2 / K3s host
    participant Service as Application ClusterIP Service
    participant App as Application pod
    participant DBService as PostgreSQL ClusterIP Service
    participant DB as PostgreSQL pod and persistent volume

    User->>SSM: Start authenticated port-forward session
    User->>Browser: Open the local forwarded URL
    Browser->>SSM: HTTP request through local tunnel
    SSM->>Host: Forward connection; no public ingress
    Host->>Service: kubectl port-forward to application service
    Service->>App: Route request to ready application pod
    App->>DBService: Execute parameterized SQL query
    DBService->>DB: Route to PostgreSQL
    DB-->>App: Return ticket/comment data
    App-->>Browser: JSON API response or UI assets
```

The application and database Kubernetes Services are `ClusterIP`. The browser UI and API are available only through the operator's private forwarding session in this baseline.

## CI, image release, and GitOps

```mermaid
flowchart LR
    PR[Application pull request] --> CI[Application CI: tests, chart checks, image scan]
    CI -->|merge to main and successful CI| Release[Release workflow]
    Release -->|OIDC short-lived credentials| ECR[Amazon ECR]
    Release -->|build and scan tested commit| Image[Immutable container image]
    Image --> ECR
    Release -->|open/update digest-pinned change| GitOpsPR[Deployment pull request]
    GitOpsPR -->|review, checks, merge| Main[main desired state]
    Main -->|HTTPS repository polling| Argo[Argo CD]
    ECR -->|pull by digest using EC2 role| K3s[K3s workload]
    Argo -->|reconcile Helm release| K3s
    K3s --> Smoke[Private smoke and readiness checks]
```

Application CI for pull requests does not receive AWS credentials. GitHub Actions publishes artifacts through a repository- and branch-scoped OIDC role; Argo CD is the only component that reconciles Kubernetes desired state.

## Monitoring, notifications, and backups

```mermaid
flowchart LR
    App[Application metrics] --> Prom[Prometheus]
    Node[Host and Kubernetes exporters] --> Prom
    Prom --> Grafana[Grafana dashboards]
    Prom --> Rules[Alert rules]
    Rules --> AM[Alertmanager]
    AM -->|bearer-token authenticated webhook| Bridge[SNS bridge on host]
    Bridge -->|EC2 role; scoped sns:Publish| SNS[SNS email notification]
    Host[EC2 status checks] --> CW[CloudWatch alarm]
    CW --> SNS

    DB[PostgreSQL] -->|scheduled consistent dump| BackupJob[Host-side backup job]
    BackupJob -->|TLS, encrypted and versioned| S3[Private S3 backup bucket]
    S3 -->|reviewed recovery procedure| Restore[Isolated restore / host rebuild]
```

In-cluster monitoring cannot report failure of its only host; the separate CloudWatch status alarm is an independent host signal. Backups and recovery restore application data, not uncommitted changes or secrets.
