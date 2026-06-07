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


# IAM module — GitHub Actions OIDC Provider + Role
# Declared in code so terraform plan validates it, but never applied
# (no AWS account available for the one-time bootstrap)
module "iam" {
  source = "./modules/iam"

  github_repository = var.github_repository
  environment       = var.environment
}
