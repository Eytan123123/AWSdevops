# Observability — CloudWatch Log Groups + Alarms (project spec requirement)
#
# Creates:
#   - One Log Group per microservice (8 by default)
#   - CPU alarm on the Auto Scaling Group  (> 80%)
#   - 5xx alarm on the ALB Target Group    (> 1% of requests)


# 1. CloudWatch Log Group — application logs from the microservice land here.
#    POC keeps a single log group; production would create one per microservice.
#
#    Encryption uses the AWS-managed CloudWatch KMS key (default). A
#    customer-managed key would give finer control but is not required by the
#    project spec and would add cost.
# trivy:ignore:AVD-AWS-0017
resource "aws_cloudwatch_log_group" "app" {
  name              = "/app/${var.service_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "/app/${var.service_name}"
    Environment = var.environment
  }
}


# 2. Alarm — average CPU on the ASG above 80% for two consecutive minutes.
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "ec2-asg-cpu-high"
  alarm_description   = "Average CPU on the application ASG is above 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  tags = {
    Name        = "ec2-asg-cpu-high"
    Environment = var.environment
  }
}


# 3. Alarm — HTTP 5xx errors from the targets above 1% of requests.
#    Uses an expression that divides HTTPCode_Target_5XX_Count by RequestCount.
resource "aws_cloudwatch_metric_alarm" "alb_5xx_rate" {
  alarm_name          = "alb-5xx-error-rate-high"
  alarm_description   = "More than 1% of ALB target responses are 5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 1

  metric_query {
    id          = "error_rate"
    expression  = "100 * (errors / requests)"
    label       = "5xx error rate (%)"
    return_data = true
  }

  metric_query {
    id = "errors"
    metric {
      metric_name = "HTTPCode_Target_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
        TargetGroup  = var.target_group_arn_suffix
      }
    }
  }

  metric_query {
    id = "requests"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
        TargetGroup  = var.target_group_arn_suffix
      }
    }
  }

  tags = {
    Name        = "alb-5xx-error-rate-high"
    Environment = var.environment
  }
}
