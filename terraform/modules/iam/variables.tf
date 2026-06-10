# Inputs for the IAM module

variable "github_repository" {
  description = "GitHub repository allowed to assume the role, in the format owner/repo"
  type        = string
}

variable "environment" {
  description = "Environment tag applied to all resources (dev / staging / prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where Security Groups will live"
  type        = string
}

variable "app_port" {
  description = "TCP port the application listens on inside the container"
  type        = number
}

variable "db_port" {
  description = "TCP port PostgreSQL listens on (5432 is the default)"
  type        = number
}
