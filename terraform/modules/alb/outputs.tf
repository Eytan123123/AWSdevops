# Outputs exposed by the ALB module

output "alb_dns_name" {
  description = "Public DNS name of the ALB (users hit this address)"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB (used when creating Route53 alias records)"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the Target Group (consumed by the EC2 module to register instances)"
  value       = aws_lb_target_group.app.arn
}

output "route53_zone_id" {
  description = "ID of the Route 53 hosted zone for the application domain"
  value       = aws_route53_zone.main.zone_id
}

output "app_fqdn" {
  description = "Fully-qualified domain name users hit (alias to the ALB)"
  value       = aws_route53_record.app.fqdn
}
