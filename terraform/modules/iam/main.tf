# IAM module — GitHub Actions OIDC Provider + Role for the CI pipeline
#
# This module declares the resources that AWS would need so the CI workflow
# can authenticate via OIDC and run terraform plan against AWS.
#
# IMPORTANT: This code is never applied (no AWS account available).
# It exists to demonstrate the correct setup and would be applied once,
# manually, on a real bootstrap. After bootstrap, the CI pipeline uses these
# resources to authenticate without long-lived access keys.


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
# - Permissions: ReadOnlyAccess (enough for `terraform plan` to inspect AWS state)
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


# 3. Attach AWS-managed ReadOnlyAccess to the role
# `terraform plan` only needs to READ AWS state, never modify it.
resource "aws_iam_role_policy_attachment" "github_actions_readonly" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
