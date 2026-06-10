# Outputs exposed by the ALB module — only values consumed elsewhere in the code.

# Consumed by: root outputs.tf (project spec requires exposing ALB DNS).
output "alb_dns_name" {
  description = "Public DNS name of the ALB (users hit this address)"
  value       = aws_lb.main.dns_name
}

# Consumed by: module.ec2 (the Auto Scaling Group registers instances to this
# Target Group via the target_group_arns attribute).
output "target_group_arn" {
  description = "ARN of the Target Group (consumed by the EC2 module to register instances)"
  value       = aws_lb_target_group.app.arn
}

# Consumed by: module.ec2 (CloudWatch alarm on ALB 5xx errors — uses the ARN
# suffix as the LoadBalancer dimension).
output "alb_arn_suffix" {
  description = "ARN suffix of the ALB (used as a CloudWatch metric dimension)"
  value       = aws_lb.main.arn_suffix
}

# Consumed by: module.ec2 (same alarm as above — uses TG suffix as dimension).
output "target_group_arn_suffix" {
  description = "ARN suffix of the Target Group (used as a CloudWatch metric dimension)"
  value       = aws_lb_target_group.app.arn_suffix
}
