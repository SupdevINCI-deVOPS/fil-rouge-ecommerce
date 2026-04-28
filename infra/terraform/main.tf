# ============================================================
# main.tf — Infrastructure AWS pour l'app e-commerce
# 2 environnements avec réseaux COMPLÈTEMENT séparés :
#
#   PREPROD :
#     - VPC       : 10.0.0.0/16
#     - Subnet    : 10.0.1.0/24
#     - Region AZ : eu-west-3a
#     - SSH       : ouvert à tous
#     - VM        : t2.micro (free tier)
#     - Disque    : 20GB
#
#   PROD :
#     - VPC       : 10.1.0.0/16   ← plage différente
#     - Subnet    : 10.1.1.0/24   ← plage différente
#     - Region AZ : eu-west-3b    ← AZ différente
#     - SSH       : restreint à ton IP uniquement
#     - VM        : t2.small (2GB RAM)
#     - Disque    : 30GB
#
# Pourquoi séparer les réseaux ?
#   - Isolation totale : un bug en preprod n'affecte jamais la prod
#   - Sécurité : impossible de joindre la prod depuis la preprod
#   - Best practice DevOps / cloud
# ============================================================


# ------------------------------------------------------------
# 1. PROVIDER AWS
# Utilise automatiquement les credentials de "aws configure"
# ------------------------------------------------------------
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


# ============================================================
# LOCALS — calcul automatique des plages réseau selon l'env
# preprod → cidr_prefix = "10.0" → VPC 10.0.0.0/16
# prod    → cidr_prefix = "10.1" → VPC 10.1.0.0/16
# Les 2 réseaux ne se chevauchent JAMAIS
# ============================================================
locals {
  cidr_prefix       = var.environment == "prod" ? "10.1" : "10.0"
  vpc_cidr          = "${local.cidr_prefix}.0.0/16"
  subnet_cidr       = "${local.cidr_prefix}.1.0/24"

  # AZ différente par environnement — best practice
  # preprod → eu-west-3a
  # prod    → eu-west-3b
  availability_zone = var.environment == "prod" ? "${var.aws_region}b" : "${var.aws_region}a"
}


# ------------------------------------------------------------
# 2. VPC — Réseau privé isolé
# preprod : 10.0.0.0/16
# prod    : 10.1.0.0/16
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
# preprod : 10.0.1.0/24  dans eu-west-3a
# prod    : 10.1.1.0/24  dans eu-west-3b
# map_public_ip_on_launch = true → IP publique attribuée auto
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
# La porte de sortie vers internet
# Chaque env a son propre IGW → isolation totale du trafic
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
# Indique que tout le trafic (0.0.0.0/0) passe par l'IGW
# Sans ça, le subnet est isolé même avec un IGW
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

# Branche la route table sur le subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


# ------------------------------------------------------------
# 6. SECURITY GROUP (Firewall)
# Règles DIFFÉRENTES entre preprod et prod :
#
#   PREPROD → SSH ouvert à tous    (0.0.0.0/0)
#   PROD    → SSH restreint à ton IP (var.my_ip dans prod.tfvars)
#
# C'est la best practice : en prod on ne laisse pas le SSH
# ouvert à tout internet
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

  # Port 3003 — API Gateway ecommerce
  ingress {
    description = "API Gateway"
    from_port   = 3003
    to_port     = 3003
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 3000 — Grafana
  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 9090 — Prometheus
  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tout le trafic sortant autorisé
  # Nécessaire pour apt install, docker pull, etc.
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
# Lit ta clé publique depuis ton Mac (~/.ssh/id_ed25519.pub)
# Injectée dans la VM automatiquement
# Connexion : ssh -i ~/.ssh/id_ed25519 ec2-user@<IP>
# ------------------------------------------------------------
resource "aws_key_pair" "deployer" {
  key_name   = "key-ecommerce-${var.environment}"
  public_key = file("~/.ssh/id_ed25519.pub")

  tags = {
    Environment = var.environment
  }
}


# ------------------------------------------------------------
# 8. EC2 INSTANCE (La VM)
# preprod : t2.micro  (1 CPU, 1GB RAM, FREE TIER)  + 20GB
# prod    : t2.small  (1 CPU, 2GB RAM)              + 30GB
# Les tailles sont définies dans les fichiers tfvars
# ------------------------------------------------------------
resource "aws_instance" "vm" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = aws_key_pair.deployer.key_name

  root_block_device {
    volume_size = var.disk_size   # 20GB preprod / 30GB prod
    volume_type = "gp2"           # SSD standard
  }

  tags = {
    Name        = "vm-ecommerce-${var.environment}"
    Environment = var.environment
    Project     = "ecommerce-microservices"
    ManagedBy   = "terraform"
  }
}
