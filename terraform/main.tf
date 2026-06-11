# Required by tflint (best practice rule "terraform_required_version")
# Declares the minimum Terraform version this project supports
terraform {
  required_version = ">= 1.5.0"

  # Required by tflint (best practice rule "terraform_required_providers")
  # Declares which providers and which versions this project uses
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state backend — project spec: "S3 + DynamoDB state locking
  # (configured, not applied)". Block kept as a comment because the bucket and
  # table don't exist yet (they need a one-off bootstrap apply with admin keys).
  # To activate: create the bucket + table, then uncomment this block and run
  # `terraform init -migrate-state`.
  #
  # backend "s3" {
  #   bucket         = "aws-migration-tfstate-eytan"
  #   key            = "terraform/state.tfstate"
  #   region         = "eu-west-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

# AWS provider configuration
# Region comes from variables.tf so it is not hardcoded (project requirement)
#
# The skip_* flags + mock credentials allow `terraform plan` to run without
# real AWS credentials. This is needed because we cannot create an OIDC Role
# in AWS for CI (no AWS account available for bootstrap). With these flags,
# plan runs offline and produces meaningful output without contacting AWS.
provider "aws" {
  region = var.aws_region

  access_key = "mock_access_key"
  secret_key = "mock_secret_key"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}


# VPC module — networking foundation (VPC, subnets, IGW, NAT, route tables)
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  environment          = var.environment
}


# IAM module — OIDC, IAM roles, Security Groups, Secrets Manager
# Includes the GitHub bootstrap resources (OIDC + Role) which are never applied,
# and the runtime security primitives that the rest of the infrastructure consumes.
module "iam" {
  source = "./modules/iam"

  github_repository = var.github_repository
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  app_port          = var.app_port
  db_port           = var.db_port
}


# RDS module — PostgreSQL Multi-AZ database
module "rds" {
  source = "./modules/rds"

  environment        = var.environment
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.iam.rds_security_group_id
  db_username        = module.iam.db_username
  db_password        = module.iam.db_password
  db_port            = var.db_port
}


# ALB module — public Application Load Balancer + Target Group + Listener
# Also creates the Route 53 hosted zone and alias record (DNS layer lives here
# because it's tightly coupled to the ALB).
module "alb" {
  source = "./modules/alb"

  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = module.iam.alb_security_group_id
  app_port          = var.app_port
  domain_name       = var.domain_name
}


# EC2 module — Launch Template + ASG + scaling policy + CloudWatch Log Groups + Alarms
module "ec2" {
  source = "./modules/ec2"

  environment = var.environment
  aws_region  = var.aws_region

  # Network
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.iam.ec2_security_group_id

  # IAM
  instance_profile_name = module.iam.ec2_instance_profile_name

  # ALB
  target_group_arn        = module.alb.target_group_arn
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix

  # App / DB
  app_port     = var.app_port
  db_host      = module.rds.db_endpoint
  db_port      = var.db_port
  db_secret_id = "rds-db-credentials"
}


# ─── Remote-state bootstrap resources ───────────────────────────────────────
#
# The S3 bucket below stores the Terraform state, and the DynamoDB table
# provides distributed locking so two concurrent runs cannot corrupt it.
#
# These are the resources the commented-out `backend "s3"` block at the top of
# this file would reference. Per the project spec they are "configured, not
# applied" — they appear in `terraform plan` so anyone reading the code can see
# the intended bootstrap, but the project itself never runs apply.

# S3 bucket — holds the state file. Versioned, encrypted, fully private.
# tfsec ignores below: logging and customer KMS key are not required by the spec.
# trivy:ignore:AVD-AWS-0089
# trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket" "tfstate" {
  bucket = var.tfstate_bucket_name

  tags = {
    Name        = var.tfstate_bucket_name
    Environment = var.environment
  }
}

# Versioning — every state write keeps history; protects against accidental loss
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption — AES-256 with the AWS-managed S3 key.
# A customer-managed KMS key would give finer control but is not required by
# the project spec and would add cost.
# tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access — state files are sensitive and must stay private
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table — used by Terraform's S3 backend for state locking.
# A row with LockID = "<bucket>/<key>" is written when a run starts and removed
# when it ends, preventing two concurrent applies.
#
# Encryption uses the AWS-managed DynamoDB KMS key (default). A customer-managed
# key and point-in-time recovery are not required for an ephemeral lock table.
# tfsec:ignore:aws-dynamodb-enable-at-rest-encryption
# tfsec:ignore:aws-dynamodb-table-customer-key
# tfsec:ignore:aws-dynamodb-enable-recovery
resource "aws_dynamodb_table" "tfstate_lock" {
  name         = var.tfstate_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = var.tfstate_lock_table_name
    Environment = var.environment
  }
}
