# ============================================================
# preprod/terraform.tfvars
# Réseau : 10.0.0.0/16 — AZ : eu-west-3a
# VM     : t3.micro (FREE TIER) — 20GB
# SSH    : ouvert à tous (pratique pour le dev)
# ============================================================

environment   = "preprod"
aws_region    = "eu-west-3"
instance_type = "t3.micro"
disk_size     = 20
ami_id        = "ami-08461dc8cd9e834e0"
