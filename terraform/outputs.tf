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
