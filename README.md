# AWS Cloud Migration

Terraform code that moves a microservices platform from on-premise to AWS.

The platform runs 8 microservices (Java/Node.js) behind an Nginx load balancer,
with a PostgreSQL database. This project recreates that setup on AWS using
Infrastructure as Code, with full CI/CD via GitHub Actions.

## Architecture

![Architecture](architecture.png)

The full design document is in [`docs/architecture_document.html`](docs/architecture_document.html).

In short:

- **VPC** with 2 Availability Zones for high availability
- **ALB** (Application Load Balancer) in the public subnets, with Route 53 DNS
- **EC2 Auto Scaling Group** in the private subnets, running Docker containers
- **RDS PostgreSQL** in Multi-AZ mode, encrypted, with 7-day backups
- **IAM Roles** for both GitHub Actions (OIDC) and the EC2 instances
- **Security Groups** wired with least-privilege rules between every layer
- **Secrets Manager** holds the DB password (never in code)
- **CloudWatch** Log Groups and Alarms (CPU > 80%, ALB 5xx > 1%)

## Prerequisites

To run anything locally you need:

- **Terraform** 1.5 or newer ([download](https://developer.hashicorp.com/terraform/install))
- **Git** to clone the repo
- (optional) **AWS CLI** if you want to apply against a real account

Nothing else needs to be set up for `terraform plan` to work — the AWS provider
is configured with mock credentials and `skip_*` flags so plan runs offline.

## Running terraform plan locally

```bash
git clone https://github.com/Eytan123123/AWSdevops.git
cd AWSdevops/terraform

terraform init -backend=false
terraform plan
```

That's it. Terraform will show you everything it would create in AWS.

**Why `-backend=false`?** The repo defines the S3 bucket and DynamoDB table
that would hold Terraform state, but does not wire them as the active backend
(they ship "configured, not applied" per the spec). The flag tells init to
skip backend setup so plan runs purely offline. In a real deployment you'd
apply those two resources first, then add a `backend "s3"` block and re-init
without the flag.

## CI/CD pipelines

Two workflows in [`.github/workflows/`](.github/workflows):

### CI (`ci.yml`)

Runs on every push to any branch, and on every PR to `main`.

It validates the code without touching AWS:

1. `terraform fmt -check` — formatting
2. `tflint` — best practices
3. `tfsec` — security scan
4. `terraform init -backend=false`
5. `terraform validate` — config correctness
6. `terraform plan` — full plan (offline, no AWS)
7. If the run is for a PR, the plan is posted as a comment on the PR

### CD (`cd.yml`)

Runs only on push to `main` (i.e. after a PR merge).

1. Runs `terraform plan -out=tfplan`
2. Uploads the binary `tfplan` as a workflow artifact (retained 30 days)
3. Posts a readable summary on the Actions job page

CD never runs `terraform apply` — applying is left to humans, per the project spec.

### Triggering the pipelines

Just `git push`. The workflows pick it up automatically based on the trigger.

To see a run:
- Go to the repo on GitHub
- Click the **Actions** tab
- Pick a workflow on the left

## Project structure

```
AWSdevops/
├── architecture.png           # Stage 1 diagram
├── README.md                  # This file
├── docs/                      # Architecture doc + assignment PDF
├── terraform/
│   ├── main.tf                # Root: wires modules together
│   ├── variables.tf           # All configurable values
│   ├── outputs.tf             # Key resource IDs (VPC, ALB, RDS)
│   └── modules/
│       ├── vpc/               # VPC + subnets + IGW + NAT + route tables
│       ├── iam/               # OIDC + IAM Roles + SGs + Secrets Manager
│       ├── rds/               # PostgreSQL Multi-AZ
│       ├── alb/               # ALB + Target Group + Listener + Route 53
│       └── ec2/               # Launch Template + ASG + Log Groups + Alarms
└── .github/
    └── workflows/
        ├── ci.yml             # Validate, plan, comment on PR
        └── cd.yml             # Plan, archive artifact (no apply)
```

## Bootstrap (for a real deployment)

A few resources must exist in AWS before the project can be applied properly.
They break the chicken-and-egg problem of "Terraform needs AWS to create AWS":

1. **OIDC Identity Provider for GitHub** — defined in `modules/iam/main.tf`,
   needed so the CI workflow can assume an IAM Role via OIDC instead of
   long-lived access keys.
2. **`github-actions-terraform` IAM Role** — also in `modules/iam/main.tf`,
   with read-only permissions for `terraform plan`.
3. **S3 bucket `aws-migration-tfstate-eytan`** — defined at the root in
   `terraform/main.tf`, would hold the Terraform state.
4. **DynamoDB table `terraform-state-lock`** — also at the root, would
   provide state locking so two concurrent runs cannot corrupt the state.

All four are written as Terraform resources in the repo. They show up in
`terraform plan` so anyone reading the code can see the intended bootstrap,
but the project never runs apply — these are "configured, not applied" per
the project spec.

In a real deployment they would be applied once, manually, by an admin with
their own access keys. After that, the rest of the project runs through CI
without any long-lived credentials anywhere.

## Notes

- `terraform apply` is **never** run by the pipelines. The assignment requires
  a green plan, not an actual deployment.
- The AWS provider uses mock credentials and `skip_*` flags so plan succeeds
  without contacting AWS.
- All secrets live in either AWS Secrets Manager or GitHub Actions Secrets —
  never in source code.
- All resources are tagged with `Name` and `Environment`.
