# All configurable values for the project — no hardcoded values in resources
# (project requirement: use variables.tf for all configurable values)

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "eu-west-1"
  #default     = "il-central-1"
  
}

variable "environment" {
  description = "Environment name applied as a tag on every resource (dev / staging / prod)"
  type        = string
  default     = "dev"
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the OIDC role, in the format owner/repo"
  type        = string
  default     = "Eytan123123/AWSdevops"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs to spread subnets across (must match aws_region)"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "app_port" {
  description = "TCP port the microservice listens on inside the container"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "TCP port PostgreSQL listens on"
  type        = number
  default     = 5432
}

variable "domain_name" {
  description = "Apex domain name for the Route 53 hosted zone (e.g., mycompany.com)"
  type        = string
  default     = "mycompany.com"
}

variable "tfstate_bucket_name" {
  description = "Name of the S3 bucket that holds the Terraform state"
  type        = string
  default     = "aws-migration-tfstate-eytan"
}

variable "tfstate_lock_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking"
  type        = string
  default     = "terraform-state-lock"
}
