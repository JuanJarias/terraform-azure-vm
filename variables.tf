variable "resource_group_name" {
  description = "Nombre del grupo de recursos de Azure."
  type        = string
  default     = "rg-terraform-juan"
}

variable "location" {
  description = "Región de Azure para el despliegue."
  type        = string
  default     = "East US"
}

variable "prefix" {
  description = "Prefijo usado para nombrar recursos."
  type        = string
  default     = "tfvmjuan"
}

variable "vm_name" {
  description = "Nombre de la máquina virtual."
  type        = string
  default     = "vm-ubuntu-terraform"
}

variable "vm_size" {
  description = "SKU o tamaño de la máquina virtual."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Usuario administrador de la VM Linux."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Clave pública SSH para acceder a la VM."
  type        = string
  sensitive   = true
}

variable "allowed_ssh_ip" {
  description = "IP o bloque CIDR autorizado para conectarse por SSH."
  type        = string
}
