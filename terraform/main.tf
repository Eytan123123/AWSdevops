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
provider "aws" {
  region = var.aws_region
}
