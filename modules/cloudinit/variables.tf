variable "vms" {
  description = "Mapa de VMs (apenas linux e vyos) que usam cloud-init"
  type = map(object({
    os_type  = string
    hostname = string
    ssh_public = object({
      type        = string
      key         = string
      host_origin = string
    })
    networks = list(object({
      name           = string
      ipv4_address   = optional(string)
      ipv4_prefix    = optional(number)
      ipv4_gateway   = optional(string)
      ipv6_address   = optional(string)
      ipv6_prefix    = optional(number)
      ipv6_gateway   = optional(string)
      dns_servers    = optional(list(string), [])
      wait_for_lease = optional(bool, false)
    }))
  }))
}

variable "storage_pool" {
  description = "Nome do storage pool Libvirt"
  type        = string
}