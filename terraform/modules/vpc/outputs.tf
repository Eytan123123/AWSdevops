# Outputs exposed by the VPC module — only values consumed elsewhere in the code.

# Consumed by: module.iam (Security Groups attach to this VPC),
#              module.alb (Target Group must be in the VPC).
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

# Consumed by: module.alb (the ALB spans both public subnets, one node per AZ).
output "public_subnet_ids" {
  description = "IDs of the public subnets (in the same order as availability_zones)"
  value       = aws_subnet.public[*].id
}

# Consumed by: module.rds (DB Subnet Group must reference 2 private subnets in different AZs).
#              Will also be consumed by module.ec2 when the ASG launches instances there.
output "private_subnet_ids" {
  description = "IDs of the private subnets (in the same order as availability_zones)"
  value       = aws_subnet.private[*].id
}
