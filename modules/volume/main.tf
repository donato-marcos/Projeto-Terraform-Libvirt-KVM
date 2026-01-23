locals {
  # Achata a lista de discos: [ { vm_name, disk_name, config }, ... ]
  flat_disks = flatten([
    for vm_name, vm in var.vms : [
      for disk in vm.disks : {
        vm_name   = vm_name
        disk_name = disk.name
        config    = disk
      }
    ]
  ])
}

resource "libvirt_volume" "this" {
  for_each = {
    for disk in local.flat_disks : "${disk.vm_name}-${disk.disk_name}" => disk
  }

  name = each.value.vm_name == "" ? each.value.disk_name : "${each.value.vm_name}-${each.value.disk_name}"
  pool = var.storage_pool

  target = {
    format = {
      type = try(each.value.config.backing_store.format, each.value.config.format, "qcow2")
    }
  }

  capacity = each.value.config.size_gb * 1024 * 1024 * 1024

  backing_store = each.value.config.backing_store != null ? {
    path = "${var.image_directory}/${each.value.config.backing_store.image}"
    format = {
      type = each.value.config.backing_store.format
    }
  } : null
}