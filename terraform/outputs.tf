# Root outputs — the "key resource IDs" required by the project spec:
#   "Use outputs.tf to expose key resource IDs (ALB DNS, RDS endpoint, VPC ID)"
#
# Plus one extra: the GitHub Actions Role ARN, which a human needs to paste
# into GitHub Secrets after the IAM bootstrap is applied.

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB (this is the address users connect to)"
  value       = module.alb.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS connection endpoint (address:port)"
  value       = module.rds.db_endpoint
}

output "github_actions_role_arn" {
  description = "ARN of the IAM Role to paste into GitHub Secrets as AWS_ROLE_ARN"
  value       = module.iam.github_actions_role_arn
}
