# Outputs exposed by the ALB module

# Consumed by: nothing in Terraform — informational. The Route 53 alias record
# already references the ALB DNS internally; this output exposes it for humans.
output "alb_dns_name" {
  description = "Public DNS name of the ALB (users hit this address)"
  value       = aws_lb.main.dns_name
}

# Consumed by: nothing in Terraform — informational.
output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.main.arn
}

# Consumed by: nothing in Terraform — exposed for callers who want to add their
# own Route 53 alias records. (Our own alias is created internally in this module.)
output "alb_zone_id" {
  description = "Hosted zone ID of the ALB (used when creating Route53 alias records)"
  value       = aws_lb.main.zone_id
}

# Consumed by: module.ec2 (the Auto Scaling Group registers instances to this
# Target Group via the target_group_arns attribute).
output "target_group_arn" {
  description = "ARN of the Target Group (consumed by the EC2 module to register instances)"
  value       = aws_lb_target_group.app.arn
}

# Consumed by: nothing in Terraform — informational. Useful if another team
# wants to add records to the same hosted zone (e.g., api.<domain>).
output "route53_zone_id" {
  description = "ID of the Route 53 hosted zone for the application domain"
  value       = aws_route53_zone.main.zone_id
}

# Consumed by: nothing in Terraform — informational. This is the address users
# actually type into a browser (e.g., app.mycompany.com).
output "app_fqdn" {
  description = "Fully-qualified domain name users hit (alias to the ALB)"
  value       = aws_route53_record.app.fqdn
}
