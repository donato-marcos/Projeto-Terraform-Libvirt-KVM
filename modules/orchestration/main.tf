# -------------------------------------------------
# 1. Redes
# -------------------------------------------------
module "network" {
  source   = "../network"
  networks = var.networks
}

# -------------------------------------------------
# 2. Volumes (todos os discos de todas as VMs)
# -------------------------------------------------
module "volume" {
  source          = "../volume"
  vms             = var.vms
  image_directory = var.image_directory
  storage_pool    = var.storage_pool

  depends_on = [module.network]
}

# -------------------------------------------------
# 3. Cloud-init (apenas Linux e VyOS)
# -------------------------------------------------
locals {
  cloudinit_vms = {
    for name, vm in var.vms : name => vm
    if vm.os_type == "linux" || vm.os_type == "vyos"
  }

  cloudinit_input = {
    for name, vm in local.cloudinit_vms : name => {
      os_type    = vm.os_type
      hostname   = name
      ssh_public = var.ssh_public
      networks   = vm.networks
    }
  }
}

module "cloudinit" {
  source       = "../cloudinit"
  vms          = local.cloudinit_input
  storage_pool = var.storage_pool

  depends_on = [module.volume]
}

# -------------------------------------------------
# 4. Domínios Linux e VyOS
# -------------------------------------------------
locals {
  linux_vyos_vms = {
    for name, vm in var.vms : name => vm
    if vm.os_type == "linux" || vm.os_type == "vyos"
  }
}

module "domain_linux" {
  source                = "../domain_linux"
  vms                   = local.linux_vyos_vms
  networks_map          = module.network.networks
  volumes_map           = module.volume.volumes
  cloudinit_volumes_map = module.cloudinit.cloudinit_volumes
  storage_pool          = var.storage_pool

  depends_on = [module.cloudinit]
}

# -------------------------------------------------
# 5. Domínios Windows
# -------------------------------------------------
locals {
  windows_vms = {
    for name, vm in var.vms : name => vm
    if vm.os_type == "windows"
  }
}

module "domain_win" {
  source       = "../domain_win"
  vms          = local.windows_vms
  networks_map = module.network.networks
  volumes_map  = module.volume.volumes
  storage_pool = var.storage_pool

  depends_on = [module.volume]
}