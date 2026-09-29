# --- Secrets / configuração local ---
variable "ssh_public" {
  description = "Chave SSH pública para cloud-init"
  type        = any
}

variable "storage_pool" {
  description = "Nome do storage pool Libvirt"
  type        = string
}

variable "libvirt_uri" {
  description = "URI do Libvirt (ex: qemu:///system)"
  type        = string
}

variable "image_directory" {
  description = "Diretório das imagens base"
  type        = string
}

# --- Infraestrutura ---
variable "networks" {
  description = "Lista de redes a serem criadas"
  type        = any
}

variable "vms" {
  description = "Mapa de VMs a serem provisionadas"
  type        = any
}