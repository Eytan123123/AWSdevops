# Inputs for the VPC module

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of AZs to spread subnets across (one subnet of each kind per AZ)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets, one per AZ in the same order as availability_zones"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets, one per AZ in the same order as availability_zones"
  type        = list(string)
}

variable "environment" {
  description = "Environment tag applied to all resources (dev / staging / prod)"
  type        = string
}
