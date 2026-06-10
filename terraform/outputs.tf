# Outputs exposed by the root module — visible in `terraform output` and the
# CD job summary. These are for HUMANS or external tooling, not other modules.

# Consumed by: humans / Route 53 / GitHub Secrets workflow. The Provider ARN is
# informational — useful when debugging the OIDC trust chain.
output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC Identity Provider"
  value       = module.iam.oidc_provider_arn
}

# Consumed by: humans — this is the value you paste into the GitHub repo as
# the AWS_ROLE_ARN secret so CI can assume the role via OIDC.
output "github_actions_role_arn" {
  description = "ARN of the IAM Role that GitHub Actions assumes via OIDC"
  value       = module.iam.github_actions_role_arn
}

# Consumed by: humans / debugging — what VPC was created.
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

# Consumed by: humans / debugging.
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

# Consumed by: humans / debugging.
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# Consumed by: humans / debugging — confirms the Instance Profile was created.
output "ec2_instance_profile_name" {
  description = "Name of the EC2 Instance Profile"
  value       = module.iam.ec2_instance_profile_name
}

# Consumed by: humans — confirms the secret exists. The application reads it at
# runtime by name (no need to know the ARN ahead of time).
output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret with the RDS credentials"
  value       = module.iam.db_credentials_secret_arn
}

# Consumed by: humans / external tooling — where to point a DB client.
output "rds_endpoint" {
  description = "RDS connection endpoint (address:port)"
  value       = module.rds.db_endpoint
}

# Consumed by: humans — alternate form of rds_endpoint without the port.
output "rds_address" {
  description = "RDS hostname"
  value       = module.rds.db_address
}

# Consumed by: humans — the raw ALB DNS (without the friendly Route 53 alias).
output "alb_dns_name" {
  description = "Public DNS name of the ALB"
  value       = module.alb.alb_dns_name
}

# Consumed by: nothing right now — exposed for clarity. Once the EC2 module
# exists, the ASG inside it will reference module.alb.target_group_arn directly.
output "alb_target_group_arn" {
  description = "ARN of the ALB Target Group (consumed by the EC2 Auto Scaling Group)"
  value       = module.alb.target_group_arn
}

# Consumed by: humans — the address users actually type into a browser.
output "app_fqdn" {
  description = "Public FQDN users hit (Route 53 alias to the ALB)"
  value       = module.alb.app_fqdn
}
