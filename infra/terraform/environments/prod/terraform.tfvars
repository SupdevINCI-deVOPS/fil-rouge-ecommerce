# ============================================================
# prod/terraform.tfvars
# Réseau : 10.1.0.0/16 — AZ : eu-west-3b  ← différent de preprod
# VM     : t2.small (1 CPU, 2GB RAM) — 30GB
# SSH    : restreint à ton IP uniquement (sécurité renforcée)
# ============================================================

environment   = "prod"
aws_region    = "eu-west-3"
instance_type = "t2.small"
disk_size     = 30
ami_id        = "ami-08461dc8cd9e834e0"
my_ip         = "185.13.180.223"