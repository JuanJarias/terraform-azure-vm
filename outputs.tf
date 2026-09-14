output "resource_group_name" {
  description = "Nombre del grupo de recursos creado."
  value       = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  description = "Dirección IP pública de la VM."
  value       = azurerm_public_ip.pip.ip_address
}

output "ssh_command" {
  description = "Comando para acceder por SSH a la VM."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}
