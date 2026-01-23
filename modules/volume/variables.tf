variable "vms" {
  description = "Mapa de VMs com suas configurações de disco"
  type = map(object({
    disks = list(object({
      name     = string
      size_gb  = number
      bootable = optional(bool, false)

      backing_store = optional(object({
        image  = string
        format = optional(string, "qcow2")
      }))

      format = optional(string, "qcow2")
    }))
  }))
}

variable "image_directory" {
  description = "Diretório onde as imagens base estão armazenadas"
  type        = string
}

variable "storage_pool" {
  description = "Nome do storage pool Libvirt"
  type        = string
}