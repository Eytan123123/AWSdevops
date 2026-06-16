# Inputs for the RDS module

variable "environment" {
  description = "Environment tag applied to all resources (dev / staging / prod)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs (must span at least 2 AZs for Multi-AZ to work)"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security Group attached to the RDS instance (allows PostgreSQL from EC2)"
  type        = string
}

variable "db_username" {
  description = "Master username for the DB instance"
  type        = string
}

variable "db_password" {
  description = "Master password for the DB instance (sourced from Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "TCP port PostgreSQL listens on"
  type        = number
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.9"
}

variable "instance_class" {
  description = "RDS instance class (e.g., db.t3.medium)"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial storage size in GB (matches the 500 GB on-premise DB per the project spec)"
  type        = number
  default     = 500
}

variable "max_allocated_storage" {
  description = "Upper bound for storage autoscaling (GB) — leaves headroom above the initial allocation"
  type        = number
  default     = 1000
}

variable "deletion_protection" {
  description = "Prevent accidental deletion (set true for production)"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy (acceptable for dev, set false for prod)"
  type        = bool
  default     = true
}
