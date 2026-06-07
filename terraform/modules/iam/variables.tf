# Inputs for the IAM module

variable "github_repository" {
  description = "GitHub repository allowed to assume the role, in the format owner/repo"
  type        = string
}

variable "environment" {
  description = "Environment tag applied to all resources (dev / staging / prod)"
  type        = string
}
