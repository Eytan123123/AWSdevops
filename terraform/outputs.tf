# Root outputs — the "key resource IDs" required by the project spec:
#   "Use outputs.tf to expose key resource IDs (ALB DNS, RDS endpoint, VPC ID)"
#
# Plus one extra: the GitHub Actions Role ARN, which a human needs to paste
# into GitHub Secrets after the IAM bootstrap is applied.

# Consumed by: humans — required by project spec ("key resource IDs").
# Example value: vpc-0a1b2c3d4e5f67890
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

# Consumed by: humans — required by project spec ("key resource IDs").
# This is the address users actually connect to in the browser.
# Example value: main-alb-1234567890.eu-west-1.elb.amazonaws.com
output "alb_dns_name" {
  description = "Public DNS name of the ALB (this is the address users connect to)"
  value       = module.alb.alb_dns_name
}

# Consumed by: humans — required by project spec ("key resource IDs").
# Useful for connecting a DB client or for the application to read at runtime.
# Example value: main-postgres.abc123.eu-west-1.rds.amazonaws.com:5432
output "rds_endpoint" {
  description = "RDS connection endpoint (address:port)"
  value       = module.rds.db_endpoint
}

# Consumed by: humans — paste this value into the GitHub repo as a Secret
# (AWS_ROLE_ARN) so the CI workflow can assume the role via OIDC.
# Example value: arn:aws:iam::123456789012:role/github-actions-terraform
output "github_actions_role_arn" {
  description = "ARN of the IAM Role to paste into GitHub Secrets as AWS_ROLE_ARN"
  value       = module.iam.github_actions_role_arn
}
