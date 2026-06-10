# Outputs exposed by the EC2 module — only values consumed elsewhere or by humans.

# Consumed by: humans / debugging — confirms the ASG was created.
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

# Consumed by: humans — confirms the Launch Template is in place.
output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.app.id
}
