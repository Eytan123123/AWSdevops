# Inputs for the ALB module

variable "environment" {
  description = "Environment tag applied to all resources (dev / staging / prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the Target Group lives"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs the ALB will span (one per AZ)"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security Group attached to the ALB"
  type        = string
}

variable "app_port" {
  description = "TCP port the application listens on (the ALB forwards to this port on EC2)"
  type        = number
}

variable "health_check_path" {
  description = "HTTP path the ALB hits to check instance health"
  type        = string
  default     = "/health"
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the ALB (set true for production)"
  type        = bool
  default     = false
}
