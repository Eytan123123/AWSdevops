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
module "alb" {
  source = "./modules/alb"

  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = module.iam.alb_security_group_id
  app_port          = var.app_port
}
