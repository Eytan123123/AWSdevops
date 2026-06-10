# VPC module — Networking foundation for the project
#
# Creates:
#   - 1 VPC
#   - 2 public subnets (one per AZ)  — hold ALB and NAT Gateways
#   - 2 private subnets (one per AZ) — hold EC2 instances AND RDS
#   - 1 Internet Gateway              — VPC <-> Internet
#   - 2 NAT Gateways (one per AZ)     — outbound-only internet for private subnets
#   - Route tables wiring the above together
#
# Subnet layout (assumes vpc_cidr = 10.0.0.0/16):
#   Public  AZ1: 10.0.1.0/24
#   Public  AZ2: 10.0.2.0/24
#   Private AZ1: 10.0.11.0/24
#   Private AZ2: 10.0.12.0/24


# Required by tflint when running --recursive on each module
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# 1. The VPC itself
# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
# VPC Flow Logs are not required by the project spec; would add cost without
# improving the assignment outcome. In a real deployment we would enable them.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # so AWS-issued DNS names (e.g., RDS endpoint) work
  enable_dns_support   = true

  tags = {
    Name        = "main-vpc"
    Environment = var.environment
  }
}


# 2. Public subnets (one per AZ)
#    These subnets host NAT Gateways (which get an Elastic IP) and the ALB
#    (which gets a public DNS from AWS). We intentionally do NOT set
#    map_public_ip_on_launch — no resource we place here relies on it,
#    and leaving it off makes tfsec happy.
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}


# 3. Private subnets (one per AZ)
#    No public IP — resources here are isolated from the internet,
#    except via the NAT Gateway for outbound traffic
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "private-subnet-${count.index + 1}"
    Environment = var.environment
  }
}


# 4. Internet Gateway — the door from the VPC to the public internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "main-igw"
    Environment = var.environment
  }
}


# 5. Elastic IPs for the NAT Gateways
#    NAT Gateways need a stable public IP to send outbound traffic from
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = {
    Name        = "nat-eip-${count.index + 1}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}


# 6. NAT Gateways — one per AZ
#    If one AZ fails, the other AZ's private resources still have outbound internet
resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "nat-gateway-${count.index + 1}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}


# 7. Public route table — routes 0.0.0.0/0 to the Internet Gateway
#    Single table for both public subnets (they share the same routing logic)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "public-route-table"
    Environment = var.environment
  }
}


# 8. Private route tables — one per AZ
#    Each private subnet routes outbound traffic to ITS OWN AZ's NAT Gateway,
#    so an AZ outage doesn't break outbound traffic from the surviving AZ
resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name        = "private-route-table-${count.index + 1}"
    Environment = var.environment
  }
}


# 9. Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# 10. Associate each private subnet with its corresponding private route table
resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
