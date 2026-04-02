output "created_networks" {
  description = "Redes criadas no Libvirt"
  value       = module.orchestration.networks
}

output "created_volumes" {
  description = "Volumes de disco criados"
  value       = module.orchestration.volumes
}

output "created_cloudinits" {
  description = "Volumes de disco criados"
  value       = module.orchestration.cloudinit_volumes
}

#output "created_linux_vyos_domains" {
#  description = "Máquinas virtuais Linux e VyOS"
#  value       = module.orchestration.linux_vyos_domains
#}
#
#output "created_windows_domains" {
#  description = "Máquinas virtuais Windows"
#  value       = module.orchestration.windows_domains
#}

#output "created_domains" {
#  description = "Máquinas virtuais [{Linux, Windows}]"
#  value       = merge(
#    module.orchestration.linux_vyos_domains,
#    module.orchestration.windows_domains
#  )
#}

output "provisioned_vms" {
  description = "Visão consolidada das VMs provisionadas"
  value       = module.orchestration.provisioned_vms
}