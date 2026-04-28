# ============================================================
# variables.tf — Déclaration de toutes les variables
# Les valeurs concrètes sont dans terraform.tfvars
# ============================================================

variable "aws_region" {
  description = "Région AWS (eu-west-3 = Paris)"
  type        = string
  default     = "eu-west-3"
}

variable "environment" {
  description = "Environnement : preprod ou prod"
  type        = string

  validation {
    condition     = contains(["preprod", "prod"], var.environment)
    error_message = "La valeur doit être preprod ou prod."
  }
}

variable "ami_id" {
  description = "ID AMI Ubuntu 22.04 LTS — Paris (eu-west-3)"
  type        = string
  default     = "ami-08461dc8cd9e834e0"
}

variable "instance_type" {
  description = "Type EC2 : t2.micro (preprod/free) ou t2.small (prod)"
  type        = string
}

variable "disk_size" {
  description = "Taille du disque en GB : 20 preprod / 30 prod"
  type        = number
}

variable "my_ip" {
  description = "Ton IP publique — utilisée pour restreindre SSH en prod"
  type        = string
  default     = "0.0.0.0"   # remplace par ton IP en prod
}
