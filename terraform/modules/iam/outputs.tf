# Outputs exposed by the IAM module

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC Identity Provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_actions_role_arn" {
  description = "ARN of the IAM Role that GitHub Actions assumes via OIDC"
  value       = aws_iam_role.github_actions.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 Instance Profile (used in the EC2 Launch Template)"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "alb_security_group_id" {
  description = "ID of the ALB Security Group"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "ID of the EC2 Security Group"
  value       = aws_security_group.ec2.id
}

output "rds_security_group_id" {
  description = "ID of the RDS Security Group"
  value       = aws_security_group.rds.id
}

output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the RDS credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}
