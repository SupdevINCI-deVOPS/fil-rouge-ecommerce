# ============================================================
# main.tf — Infrastructure AWS pour l'app e-commerce
# 2 environnements avec réseaux COMPLÈTEMENT séparés :
#
#   PREPROD :
#     - VPC       : 10.0.0.0/16
#     - Subnet    : 10.0.1.0/24
#     - Region AZ : eu-west-3a
#     - SSH       : ouvert à tous
#     - VM        : t3.micro (free tier)
#     - Disque    : 20GB
#
#   PROD :
#     - VPC       : 10.1.0.0/16
#     - Subnet    : 10.1.1.0/24
#     - Region AZ : eu-west-3b
#     - SSH       : restreint à ton IP uniquement
#     - VM        : t3.small (2GB RAM)
#     - Disque    : 30GB
# ============================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  cidr_prefix       = var.environment == "prod" ? "10.1" : "10.0"
  vpc_cidr          = "${local.cidr_prefix}.0.0/16"
  subnet_cidr       = "${local.cidr_prefix}.1.0/24"
  availability_zone = var.environment == "prod" ? "${var.aws_region}b" : "${var.aws_region}a"
}

# ------------------------------------------------------------
# 2. VPC
# ------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "vpc-ecommerce-${var.environment}"
    Environment = var.environment
    Project     = "ecommerce-microservices"
    ManagedBy   = "terraform"
  }
}

# ------------------------------------------------------------
# 3. SUBNET PUBLIC
# ------------------------------------------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.subnet_cidr
  availability_zone       = local.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name        = "subnet-public-ecommerce-${var.environment}"
    Environment = var.environment
    Type        = "public"
  }
}

# ------------------------------------------------------------
# 4. INTERNET GATEWAY
# ------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "igw-ecommerce-${var.environment}"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# 5. ROUTE TABLE
# ------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "rt-public-ecommerce-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------
# 6. SECURITY GROUP (Firewall)
# Ports ouverts :
#   22    → SSH
#   3000  → Backend Node.js API
#   8000  → Frontend Vue.js
#   8081  → Mongo Express (admin DB)
#   9090  → Prometheus (monitoring)
#   3001  → Grafana (monitoring)
# Port FERMÉ :
#   27017 → MongoDB (interne Docker uniquement)
# ------------------------------------------------------------
resource "aws_security_group" "sg" {
  name        = "ecommerce-sg-${var.environment}"
  description = "Security group ${var.environment} ecommerce"
  vpc_id      = aws_vpc.main.id

  # SSH — restreint en prod, ouvert en preprod
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.environment == "prod" ? ["${var.my_ip}/32"] : ["0.0.0.0/0"]
  }

  # Port 3000 — Backend Node.js API
  ingress {
    description = "Backend API"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 8000 — Frontend Vue.js
  ingress {
    description = "Frontend Vue.js"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 8081 — Mongo Express admin
  ingress {
    description = "Mongo Express"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 9090 — Prometheus monitoring
  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 3001 — Grafana monitoring
  ingress {
    description = "Grafana"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 9100 — Node Exporter
  ingress {
    description = "Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tout le trafic sortant autorisé
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sg-ecommerce-${var.environment}"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# 7. KEY PAIR SSH
# ------------------------------------------------------------
resource "aws_key_pair" "deployer" {
  key_name   = "key-ecommerce-${var.environment}"
  public_key = file("~/.ssh/id_ed25519.pub")

  tags = {
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# 8. EC2 INSTANCE
# ------------------------------------------------------------
resource "aws_instance" "vm" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = aws_key_pair.deployer.key_name

  user_data = <<-EOF
    #!/bin/bash
    systemctl stop firewalld
    systemctl disable firewalld
  EOF

  root_block_device {
    volume_size = var.disk_size
    volume_type = "gp2"
  }

  tags = {
    Name        = "vm-ecommerce-${var.environment}"
    Environment = var.environment
    Project     = "ecommerce-microservices"
    ManagedBy   = "terraform"
  }
}
