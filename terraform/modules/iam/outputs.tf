# Outputs exposed by the IAM module

# Consumed by: nothing in Terraform — kept for visibility / debugging.
# The OIDC Provider ARN is informational; the Role's trust policy already
# references it internally.
output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC Identity Provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

# Consumed by: nothing in Terraform — but the human operator copies this value
# into the GitHub repo as a Secret (AWS_ROLE_ARN) so the CI workflow can assume it.
output "github_actions_role_arn" {
  description = "ARN of the IAM Role that GitHub Actions assumes via OIDC"
  value       = aws_iam_role.github_actions.arn
}

# Consumed by: module.ec2 (Launch Template — every EC2 instance gets this profile,
# which gives it access to ECR, Secrets Manager, and CloudWatch).
output "ec2_instance_profile_name" {
  description = "Name of the EC2 Instance Profile (used in the EC2 Launch Template)"
  value       = aws_iam_instance_profile.ec2_profile.name
}

# Consumed by: module.alb (the ALB is launched with this SG attached).
output "alb_security_group_id" {
  description = "ID of the ALB Security Group"
  value       = aws_security_group.alb.id
}

# Consumed by: module.ec2 (Launch Template applies this SG to every instance).
output "ec2_security_group_id" {
  description = "ID of the EC2 Security Group"
  value       = aws_security_group.ec2.id
}

# Consumed by: module.rds (the RDS instance is launched with this SG attached).
output "rds_security_group_id" {
  description = "ID of the RDS Security Group"
  value       = aws_security_group.rds.id
}

# Consumed by: nothing in Terraform — informational. At runtime, EC2 instances
# call AWS API with this ARN to fetch the live DB credentials.
output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the RDS credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

# Consumed by: module.rds (set as master_password on the DB at creation time).
# The SAME value is stored in Secrets Manager (above), so EC2 can retrieve it
# at runtime and connect with it.
output "db_password" {
  description = "Generated DB password (consumed by the RDS module at creation time)"
  value       = random_password.db.result
  sensitive   = true
}

# Consumed by: module.rds (set as master_username on the DB).
output "db_username" {
  description = "DB master username (consumed by the RDS module)"
  value       = "postgres"
}
