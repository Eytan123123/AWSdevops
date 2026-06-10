# Outputs exposed by the root module
# These values are shown after `terraform apply` and can be consumed by
# other tools (CI/CD, scripts, humans copying values into GitHub Secrets).

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC Identity Provider"
  value       = module.iam.oidc_provider_arn
}

output "github_actions_role_arn" {
  description = "ARN of the IAM Role that GitHub Actions assumes via OIDC"
  value       = module.iam.github_actions_role_arn
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 Instance Profile"
  value       = module.iam.ec2_instance_profile_name
}

output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret with the RDS credentials"
  value       = module.iam.db_credentials_secret_arn
}

output "rds_endpoint" {
  description = "RDS connection endpoint (address:port)"
  value       = module.rds.db_endpoint
}

output "rds_address" {
  description = "RDS hostname"
  value       = module.rds.db_address
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB"
  value       = module.alb.alb_dns_name
}

output "alb_target_group_arn" {
  description = "ARN of the ALB Target Group (consumed by the EC2 Auto Scaling Group)"
  value       = module.alb.target_group_arn
}

output "app_fqdn" {
  description = "Public FQDN users hit (Route 53 alias to the ALB)"
  value       = module.alb.app_fqdn
}
