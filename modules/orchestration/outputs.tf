output "networks" {
  description = "Redes criadas"
  value       = module.network.networks
}

output "volumes" {
  description = "Volumes criados"
  value       = module.volume.volumes
}

output "cloudinit_volumes" {
  description = "Discos cloud-init gerados"
  value       = module.cloudinit.cloudinit_volumes
}

#output "linux_vyos_domains" {
#  description = "Domínios Linux e VyOS"
#  value       = module.domain_linux.domains
#}
#
#output "windows_domains" {
#  description = "Domínios Windows"
#  value       = module.domain_win.domains
#}

output "provisioned_vms" {
  description = "Visão consolidada das VMs provisionadas, similar ao vm.auto.tfvars"
  value = {
    for vm_name, vm_config in var.vms : vm_name => {
      # Dados da configuração original
      os_type        = vm_config.os_type
      vcpus          = vm_config.vcpus
      memory         = vm_config.memory
      current_memory = try(vm_config.current_memory, vm_config.memory)
      running        = try(vm_config.running, false)

      # Discos provisionados (nomes reais dos volumes)
      disks = [
        for disk in vm_config.disks : {
          size_gb  = disk.size_gb
          bootable = try(disk.bootable, false)
          vol_name = "${vm_name}-${disk.name}"  # nome do volume real
        }
      ]

      # Redes configuradas
      networks = vm_config.networks

      # Status desejado da VM (do Libvirt)
      status = try(vm_config.running, false) ? "running" : "shut off"
    }
  }
}