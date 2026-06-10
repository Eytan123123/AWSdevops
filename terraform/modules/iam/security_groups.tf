# Security Groups — least-privilege network firewall rules
#
# Flow:
#   Internet ──80──> ALB ──app_port──> EC2 ──db_port──> RDS
#                                       └──443──> Internet (via NAT, for ECR/Secrets/CloudWatch)
#
# We use aws_security_group_rule (separate from the SG resource) instead of
# inline rules, because EC2 SG and RDS SG reference each other and inline
# rules cause a circular dependency.


# ─── ALB SG ───────────────────────────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTPS from internet, forward to EC2 on app port"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "alb-sg"
    Environment = var.environment
  }
}

# Public-facing HTTP is the whole point of the ALB; the 0.0.0.0/0 here is intentional.
# A production deployment would use HTTPS (443) with an ACM certificate.
# tfsec:ignore:aws-vpc-no-public-ingress-sgr
resource "aws_security_group_rule" "alb_ingress_http" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP from internet"
}

resource "aws_security_group_rule" "alb_egress_to_ec2" {
  security_group_id        = aws_security_group.alb.id
  type                     = "egress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2.id
  description              = "App port to EC2 instances"
}


# ─── EC2 SG ───────────────────────────────────────────────────────────
resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Allow app traffic from ALB; outbound to RDS and to internet via NAT"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "ec2-sg"
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "ec2_ingress_from_alb" {
  security_group_id        = aws_security_group.ec2.id
  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "App port from ALB"
}

resource "aws_security_group_rule" "ec2_egress_to_rds" {
  security_group_id        = aws_security_group.ec2.id
  type                     = "egress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds.id
  description              = "PostgreSQL to RDS"
}

# Outbound HTTPS to internet so EC2 can pull from ECR, read Secrets Manager,
# and push logs to CloudWatch (the traffic egresses via the NAT Gateway)
# tfsec:ignore:aws-vpc-no-public-egress-sgr
resource "aws_security_group_rule" "ec2_egress_https" {
  security_group_id = aws_security_group.ec2.id
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS to AWS services via NAT (ECR, Secrets Manager, CloudWatch)"
}


# ─── RDS SG ───────────────────────────────────────────────────────────
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allow PostgreSQL from EC2 instances only"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "rds-sg"
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "rds_ingress_from_ec2" {
  security_group_id        = aws_security_group.rds.id
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2.id
  description              = "PostgreSQL from EC2 instances"
}
