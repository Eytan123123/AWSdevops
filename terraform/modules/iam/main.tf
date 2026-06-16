# IAM module — GitHub Actions OIDC Provider + Role for the CI pipeline
#
# This module declares the resources that AWS would need so the CI workflow
# can authenticate via OIDC and run terraform plan against AWS.
#
# BOOTSTRAP STEP (apply manually once):
# These resources must be applied first by an admin with AWS credentials.
# They enable the GitHub Actions CI workflow to assume the role via OIDC
# without long-lived access keys.
#
# After bootstrap, the CI pipeline will authenticate automatically via OIDC
# using the github-actions-terraform IAM role defined below.


# Required by tflint when running --recursive on each module
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}


# 1. OIDC Identity Provider
# Tells AWS: "I trust GitHub as an identity provider."
# Created once per AWS account.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name        = "github-actions-oidc"
    Environment = var.environment
  }
}


# 2. IAM Role assumed by GitHub Actions
# - Trust policy: only GitHub Actions runs from this specific repo may assume the role
# - Permissions: Administrator access for full control over AWS resources and state management
resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
        }
      }
    }]
  })

  tags = {
    Name        = "github-actions-terraform"
    Environment = var.environment
  }
}


# 3. Attach AdministratorAccess for full AWS permissions
# This allows the pipeline to manage all resources including IAM, state backend, and application infrastructure
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
