variable "vms" {
  description = "Mapa de VMs Talos"
  type = map(object({
    os_type        = string
    vcpus          = number
    memory         = number
    current_memory = optional(number, null)
    running        = optional(bool, false)
    video_model    = optional(string, "none")
    graphics       = optional(string, "none")
    firmware       = optional(string, "efi")
    disks = list(object({
      name     = string
      bootable = optional(bool, false)
    }))
    networks = list(object({
      name           = string
      wait_for_lease = optional(bool, false)
      mac_address    = optional(string) 
    }))
  }))
}

variable "networks_map" {
  description = "Mapa de redes criadas: { nome => { name = ... } }"
  type        = map(object({ name = string }))
}

variable "volumes_map" {
  description = "Mapa de volumes: { 'vm-disk' => { name, pool } }"
  type        = map(object({ name = string, pool = string }))
}

variable "cloudinit_volumes_map" {
  description = "Mapa de discos cloud-init: { vm_name => {  name, pool } }"
  type        = map(object({ name = string, pool = string }))
}

variable "storage_pool" {
  description = "Nome do storage pool"
  type        = string
}