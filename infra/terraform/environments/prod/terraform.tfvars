# ============================================================
# prod/terraform.tfvars
# Réseau : 10.1.0.0/16 — AZ : eu-west-3b
# VM     : t3.small (1 CPU, 2GB RAM) — 30GB
# SSH    : restreint à ton IP uniquement
# ============================================================

environment   = "prod"
aws_region    = "eu-west-3"
instance_type = "t3.small"
disk_size     = 30
ami_id        = "ami-08461dc8cd9e834e0"
my_ip         = "86.247.145.147"