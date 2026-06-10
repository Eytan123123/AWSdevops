# EC2 IAM Role + Instance Profile
#
# This role is what EC2 instances assume at boot time. It grants them
# permission to:
#   - Pull Docker images from ECR
#   - Read the RDS password from Secrets Manager
#   - Write application logs to CloudWatch


# 1. The role itself — only EC2 instances may assume it
resource "aws_iam_role" "ec2_role" {
  name = "ec2-microservice-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "ec2-microservice-role"
    Environment = var.environment
  }
}


# 2. Pull container images from ECR (managed policy, scoped to read-only)
resource "aws_iam_role_policy_attachment" "ec2_ecr_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# 3. Write logs to CloudWatch (managed policy used by the CloudWatch agent)
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


# 4. Read the DB credentials secret — scoped to the specific secret ARN
#    (principle of least privilege: not all secrets, just this one)
resource "aws_iam_role_policy" "ec2_secrets_read" {
  name = "ec2-secrets-read"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = aws_secretsmanager_secret.db_credentials.arn
    }]
  })
}


# 5. Instance Profile — the wrapper that lets EC2 actually use the role
#    (EC2 cannot reference IAM roles directly; it needs an instance profile)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-microservice-profile"
  role = aws_iam_role.ec2_role.name
}
