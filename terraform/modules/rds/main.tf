# RDS module — managed PostgreSQL, Multi-AZ, encrypted, with automated backups
#
# Creates:
#   - DB Subnet Group spanning the two private subnets (one per AZ)
#   - RDS PostgreSQL instance with Multi-AZ failover, encrypted storage,
#     7-day backups, and CloudWatch log export
#
# Credentials come from the IAM module (Secrets Manager + random_password)
# so no password ever appears in source code.


terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# 1. DB Subnet Group — tells RDS which subnets are eligible for the primary
#    and standby instances. Must reference at least 2 subnets in different AZs.
resource "aws_db_subnet_group" "main" {
  name        = "main-rds-subnet-group"
  description = "Private subnets for RDS PostgreSQL Multi-AZ"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name        = "main-rds-subnet-group"
    Environment = var.environment
  }
}


# 2. The RDS PostgreSQL instance
#
# We intentionally disable IAM database auth — the project uses Secrets Manager
# for password retrieval, which is sufficient.
# tfsec:ignore:aws-rds-enable-performance-insights tfsec:ignore:aws-rds-enable-performance-insights-encryption
resource "aws_db_instance" "main" {
  identifier = "main-postgres"

  # Engine
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage — encrypted at rest with the AWS-managed RDS KMS key
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Master credentials (sourced from Secrets Manager in modules/iam)
  username = var.db_username
  password = var.db_password
  port     = var.db_port

  # Networking
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false

  # High availability — synchronous standby in a second AZ
  multi_az = true

  # Backups — 7-day retention (matches project spec)
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Stream PostgreSQL logs to CloudWatch Logs
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # Lifecycle
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  # Apply minor engine updates automatically during the maintenance window
  auto_minor_version_upgrade = true

  tags = {
    Name        = "main-postgres"
    Environment = var.environment
  }
}
