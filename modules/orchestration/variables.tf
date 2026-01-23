# --- Infraestrutura ---
variable "networks" {
  description = "Lista de redes"
  type        = list(any)
}

variable "vms" {
  description = "Mapa completo de VMs"
  type        = any
}

# --- Configuração do ambiente ---
variable "ssh_public" {
  description = "Chave SSH pública para cloud-init"
  type        = any
}

variable "storage_pool" {
  description = "Nome do storage pool"
  type        = string
}

variable "image_directory" {
  description = "Diretório das imagens base"
  type        = string
}