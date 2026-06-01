# AWS Cloud Migration — Architecture Document

## Overview

This document describes the AWS architecture for migrating 8 microservices from on-premise to AWS.
The system must support 99.99% uptime, auto-scaling from 1,000 to 5,000 req/sec, and 50,000 concurrent users across Europe and US.

---

## 1. AWS Services Diagram — Component Description

### VPC Layout

```
Region: eu-west-1 (Ireland) — Primary

VPC: 10.0.0.0/16
│
├── Availability Zone 1 (eu-west-1a)
│   ├── Public Subnet:  10.0.1.0/24
│   │   └── NAT Gateway
│   └── Private Subnet: 10.0.3.0/24
│       ├── EC2 Auto Scaling Group (microservices)
│       └── RDS PostgreSQL (Primary)
│
└── Availability Zone 2 (eu-west-1b)
    ├── Public Subnet:  10.0.2.0/24
    │   └── (ALB node)
    └── Private Subnet: 10.0.4.0/24
        ├── EC2 Auto Scaling Group (microservices)
        └── RDS PostgreSQL (Standby — Multi-AZ)

Internet Gateway → attached to VPC
ALB → spans both public subnets
```

### Traffic Flow

```
Internet
   │
   ▼
Internet Gateway
   │
   ▼
Application Load Balancer (ALB) — public subnets, both AZs
   │  routes by path/host to target groups
   ▼
EC2 Auto Scaling Group — private subnets
   │  Docker containers pulled from ECR
   ▼
RDS PostgreSQL Multi-AZ — private subnets
```

### Supporting Services

| Service | Purpose |
|---|---|
| S3 | Terraform state storage, application artifacts |
| CloudWatch | Logs, metrics, alarms |
| IAM | Roles and policies for EC2 and CI/CD |
| ECR | Docker image registry (images pre-built, pulled at launch) |
| Secrets Manager | Database credentials |
| DynamoDB | Terraform state locking |

---

## 2. Design Decisions

### Why EC2 over ECS or Lambda?

The assignment explicitly requires **Docker containers on EC2**.
Beyond that constraint, EC2 Auto Scaling Groups make sense here because:
- The workload is long-running (microservices, not event-driven functions) — Lambda has a 15-minute timeout and cold start latency unsuitable for 50,000 concurrent users
- ECS adds orchestration complexity (task definitions, cluster management) that is unnecessary when the team is already familiar with EC2 and Docker
- EC2 gives full control over the instance, networking, and Docker runtime, which is easier to reason about and explain

### Why Multi-AZ RDS?

Multi-AZ means AWS maintains a **synchronous standby replica** in a second Availability Zone.
If the primary database instance fails (hardware failure, AZ outage), AWS automatically promotes the standby — typically in under 60 seconds — with no manual intervention.

This protects against:
- Single AZ hardware failure
- Planned maintenance windows (AWS can fail over, patch primary, fail back)
- Accidental instance termination

Without Multi-AZ, a database failure would breach the 99.99% uptime SLA.

### How Does the Architecture Achieve 99.99% Uptime?

99.99% uptime means less than **52 minutes of downtime per year**.
Three layers protect against failure:

1. **Multi-AZ EC2 Auto Scaling** — if an instance or entire AZ fails, the ASG launches replacement instances in the healthy AZ. The ALB stops routing to unhealthy instances within seconds (health check interval: 30s).
2. **Multi-AZ RDS** — automatic database failover within ~60 seconds, no manual steps.
3. **ALB health checks** — continuously probe each EC2 instance. Unhealthy instances are removed from rotation immediately, preventing traffic from reaching a broken instance.

---

## 3. Network & Security Model

### Public vs Private Subnets

| Resource | Subnet | Reason |
|---|---|---|
| ALB | Public | Must be reachable from the internet |
| NAT Gateway | Public | Needs an Elastic IP to route outbound traffic |
| EC2 instances | Private | Never directly exposed to internet |
| RDS | Private | Database must never be internet-accessible |

EC2 instances access the internet (e.g., to pull from ECR) via the **NAT Gateway** — outbound only, no inbound access.

### Security Groups

**ALB Security Group**
- Inbound: port 80 (HTTP), port 443 (HTTPS) — from `0.0.0.0/0`
- Outbound: port 8080 — to EC2 security group only

**EC2 Security Group**
- Inbound: port 8080 — from ALB security group only (not from internet)
- Outbound: port 5432 — to RDS security group
- Outbound: port 443 — to internet (via NAT, for ECR image pulls)

**RDS Security Group**
- Inbound: port 5432 — from EC2 security group only
- No outbound rules needed

This enforces **least privilege**: the database is only reachable from application servers, and application servers are only reachable from the load balancer.

### Secrets Management

Database credentials are stored in **AWS Secrets Manager** — never hardcoded in code or environment variables committed to git.

EC2 instances access Secrets Manager via an **IAM Instance Profile** (role attached to the instance). The role has only the permissions required:
- `secretsmanager:GetSecretValue` for the specific DB secret ARN
- `ecr:GetAuthorizationToken` and `ecr:BatchGetImage` to pull Docker images
- `logs:CreateLogStream` and `logs:PutLogEvents` for CloudWatch

GitHub Actions uses **OIDC** (OpenID Connect) to authenticate with AWS — no long-lived access keys stored in GitHub secrets.

---

## 4. Scaling Strategy

### Target: 1,000 to 5,000 req/sec

The Auto Scaling Group is configured with:
- `min_size = 2` — always running in both AZs for high availability
- `max_size = 10` — ceiling to control costs
- **Target Tracking Policy** on CPU utilization at 70% — AWS automatically adds or removes instances to keep average CPU near 70%

**Why CPU at 70%?**
At 70% CPU target, there is always 30% headroom before an instance is saturated. When traffic spikes, new instances launch and are registered with the ALB before existing instances become overloaded.

**Scale-out time estimate:**
- CloudWatch detects CPU breach: ~1 minute
- New EC2 instance launches: ~2 minutes
- Docker container starts and passes ALB health check: ~1 minute
- Total: ~4 minutes to add capacity

For predictable peak traffic (e.g., business hours in US/Europe), **Scheduled Scaling** can pre-warm instances before the spike, eliminating the 4-minute lag.

### ALB and the 50,000 Concurrent Users Requirement

The ALB is a managed AWS service — it scales automatically with no configuration required. It distributes connections across all healthy EC2 instances in both AZs using round-robin by default.

---

## 5. Diagram Description (for architecture.png)

Draw the following components in a VPC box:

**Left side — outside VPC:**
- Internet (cloud icon) → Internet Gateway

**Inside VPC — two columns (AZ1, AZ2):**
- Row 1 (Public subnets): NAT Gateway in AZ1, ALB spanning both (draw as single box between the two columns)
- Row 2 (Private subnets): EC2 Auto Scaling Group box containing 2 EC2 instances (one per AZ)
- Row 3 (Private subnets): RDS Primary in AZ1, RDS Standby in AZ2, connected by a sync replication arrow

**Right side — outside VPC (supporting services):**
- S3 (Terraform state)
- CloudWatch (logs + alarms)
- ECR (Docker images) — arrow from EC2 via NAT Gateway
- Secrets Manager — arrow from EC2
- DynamoDB (state lock)

**Bottom — CI/CD flow:**
- GitHub → GitHub Actions → (terraform plan only, no apply) → S3/DynamoDB backend
