# ALB module — Application Load Balancer + Target Group + Listener
#
# Creates:
#   - ALB in the public subnets (one node per AZ, AWS-managed)
#   - Target Group that EC2 instances register to via the Auto Scaling Group
#   - HTTP listener on port 80 that forwards to the Target Group
#
# Note: a production deployment would terminate HTTPS at the ALB using an ACM
# certificate (port 443). HTTP is used here to keep the assignment self-contained
# (no domain/certificate needed for terraform plan to succeed offline).


terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# 1. The ALB itself
#    Spans all public subnets — AWS places one node in each AZ for HA.
#
# trivy:ignore:AVD-AWS-0052  # ALB is intentionally public-facing
# trivy:ignore:AVD-AWS-0053  # access logs require an S3 bucket; not in project spec
resource "aws_lb" "main" {
  name               = "main-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids

  # Hardening: strip non-RFC-compliant headers before forwarding to targets
  drop_invalid_header_fields = true

  # Deletion protection controlled by a variable; defaults to false for dev
  # trivy:ignore:AVD-AWS-0054
  enable_deletion_protection = var.deletion_protection

  tags = {
    Name        = "main-alb"
    Environment = var.environment
  }
}


# 2. Target Group — list of EC2 instances the ALB forwards traffic to.
#    The Auto Scaling Group registers/deregisters instances here automatically.
resource "aws_lb_target_group" "app" {
  name        = "main-tg"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  # Health check — ALB removes unhealthy instances from rotation
  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name        = "main-tg"
    Environment = var.environment
  }
}


# 3. Listener — accepts connections on port 80 and forwards to the Target Group.
#
# trivy:ignore:AVD-AWS-0054  # HTTP listener is intentional (see file header note)
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}


# 4. Route 53 Hosted Zone — DNS zone for the application domain.
#    In a real deployment this matches a registered domain; here it stays in the
#    plan so the architecture is reflected end-to-end.
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name        = var.domain_name
    Environment = var.environment
  }
}


# 5. Route 53 alias record — points app.<domain> to the ALB.
#    Using an alias (not a CNAME) lets AWS resolve to the ALB's underlying IPs
#    and supports apex records if needed.
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
