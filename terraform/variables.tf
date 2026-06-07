# All configurable values for the project — no hardcoded values in resources
# (project requirement: use variables.tf for all configurable values)

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "eu-west-1"
}
