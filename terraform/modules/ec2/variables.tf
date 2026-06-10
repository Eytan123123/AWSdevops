# Inputs for the EC2 module

variable "environment" {
  description = "Environment tag applied to all resources (dev / staging / prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region (passed into user_data so the CLI knows where to call)"
  type        = string
}


# ─── Compute config ────────────────────────────────────────────────

variable "ami_id" {
  description = "AMI ID for the EC2 instances (Amazon Linux 2023 in eu-west-1 by default)"
  type        = string
  default     = "ami-0c1ac8a41498c1a9c"
}

variable "instance_type" {
  description = "EC2 instance class"
  type        = string
  default     = "t3.medium"
}


# ─── Network ───────────────────────────────────────────────────────

variable "private_subnet_ids" {
  description = "Private subnet IDs the ASG launches instances into"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security Group attached to every EC2 instance"
  type        = string
}


# ─── IAM ───────────────────────────────────────────────────────────

variable "instance_profile_name" {
  description = "Name of the IAM Instance Profile (gives EC2 access to ECR, Secrets, CloudWatch)"
  type        = string
}


# ─── ALB ───────────────────────────────────────────────────────────

variable "target_group_arn" {
  description = "ALB Target Group ARN — the ASG registers instances here"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix used as a CloudWatch dimension for the 5xx alarm"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target Group ARN suffix used as a CloudWatch dimension for the 5xx alarm"
  type        = string
}


# ─── App / DB ──────────────────────────────────────────────────────

variable "app_port" {
  description = "TCP port the application listens on inside the container"
  type        = number
}

variable "service_name" {
  description = "Name of the microservice container (also used as the ECR image name)"
  type        = string
  default     = "main-service"
}

variable "ecr_registry" {
  description = "ECR registry URL (e.g., 123456789012.dkr.ecr.eu-west-1.amazonaws.com)"
  type        = string
  default     = "123456789012.dkr.ecr.eu-west-1.amazonaws.com"
}

variable "db_host" {
  description = "RDS hostname the application connects to"
  type        = string
}

variable "db_port" {
  description = "DB port the application connects to"
  type        = number
}

variable "db_secret_id" {
  description = "Name/ARN of the Secrets Manager secret holding DB credentials"
  type        = string
}


# ─── Scaling ───────────────────────────────────────────────────────

variable "asg_min_size" {
  description = "Minimum number of EC2 instances (project spec: 2 — one per AZ)"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances (project spec: 10)"
  type        = number
  default     = 10
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for the Target Tracking policy"
  type        = number
  default     = 70
}


# ─── Observability ─────────────────────────────────────────────────

variable "log_retention_days" {
  description = "How many days CloudWatch keeps log events"
  type        = number
  default     = 30
}
