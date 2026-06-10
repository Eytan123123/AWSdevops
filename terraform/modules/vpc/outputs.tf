# Outputs exposed by the VPC module
# Other modules (EC2, RDS, ALB, IAM) consume these to know where to place themselves

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (in the same order as availability_zones)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (in the same order as availability_zones)"
  value       = aws_subnet.private[*].id
}
