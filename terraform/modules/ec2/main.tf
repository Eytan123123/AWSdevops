# EC2 module — Launch Template + Auto Scaling Group
#
# Creates the compute layer for the microservices:
#   - Launch Template that installs Docker and runs the container at boot
#   - Auto Scaling Group spread across the two private subnets
#   - Target Tracking scaling policy keyed to average CPU
#
# Inputs come from other modules:
#   subnets / SG / IAM profile / target group / DB endpoint


terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# 1. Launch Template — the blueprint the ASG uses for every new instance.
resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [var.security_group_id]

  # Require IMDSv2 (session-token based) — protects against SSRF attacks
  # that read instance metadata
  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
  }

  # Boot script — installs Docker and starts the microservice container.
  # templatefile() injects Terraform values into the .sh.tftpl template.
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {
    aws_region   = var.aws_region
    db_host      = var.db_host
    db_port      = var.db_port
    db_secret_id = var.db_secret_id
    app_port     = var.app_port
    service_name = var.service_name
    ecr_registry = var.ecr_registry
  }))

  # Tags applied to each instance the ASG launches
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "app-instance"
      Environment = var.environment
    }
  }

  tags = {
    Name        = "app-launch-template"
    Environment = var.environment
  }
}


# 2. Auto Scaling Group — runs the instances, registers them with the ALB.
resource "aws_autoscaling_group" "app" {
  name                = "app-asg"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_min_size
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.target_group_arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # ASG tags use a different syntax (each tag is a tag block, not a map)
  tag {
    key                 = "Name"
    value               = "app-asg"
    propagate_at_launch = false
  }
  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = false
  }
}


# 3. Target Tracking scaling policy — bonus feature noted in the project spec.
#    AWS adds/removes instances automatically to keep the average CPU near the target.
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}
