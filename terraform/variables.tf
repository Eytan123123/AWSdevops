# All configurable values for the project — no hardcoded values in resources
# (project requirement: use variables.tf for all configurable values)

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name applied as a tag on every resource"
  type        = string
  default     = "dev"
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the OIDC role, in the format owner/repo"
  type        = string
  default     = "Eytan123123/AWSdevops"
}
