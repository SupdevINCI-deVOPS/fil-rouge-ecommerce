# ============================================================
# outputs.tf — Ce que Terraform affiche après terraform apply
#
# Ces valeurs sont ESSENTIELLES pour la suite :
#   → L'IP publique sera copiée dans inventory.ini d'Ansible
#   → La commande SSH est prête à l'emploi
#   → Les URLs de l'app et du monitoring sont directement lisibles
# ============================================================

# IP publique de la VM EC2
# C'est cette valeur que tu mettras dans inventory.ini d'Ansible
output "instance_public_ip" {
  description = "IP publique de la VM — à copier dans Ansible inventory"
  value       = aws_instance.vm.public_ip
}

# DNS public AWS (alternative à l'IP)
output "instance_public_dns" {
  description = "DNS public de la VM"
  value       = aws_instance.vm.public_dns
}

# ID de l'instance EC2
output "instance_id" {
  description = "ID EC2 — utile pour aws CLI"
  value       = aws_instance.vm.id
}

# Commande SSH prête à l'emploi
# Après terraform apply, copie-colle directement cette commande
output "ssh_command" {
  description = "Commande SSH pour se connecter à la VM"
  value       = "ssh -i ~/.ssh/id_ed25519 ec2-user@${aws_instance.vm.public_ip}"
}

# URL de l'app ecommerce
output "app_url" {
  description = "URL de l'app ecommerce"
  value       = "http://${aws_instance.vm.public_ip}:3003"
}

# URL Grafana
output "grafana_url" {
  description = "URL Grafana monitoring"
  value       = "http://${aws_instance.vm.public_ip}:3000"
}

# URL Prometheus
output "prometheus_url" {
  description = "URL Prometheus monitoring"
  value       = "http://${aws_instance.vm.public_ip}:9090"
}

# Environnement déployé
output "environment" {
  description = "Environnement déployé"
  value       = var.environment
}
