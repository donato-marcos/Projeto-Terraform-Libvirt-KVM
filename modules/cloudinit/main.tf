locals {
  # Usa templates específicos se fornecidos, senão usa os do módulo
  template_dir = var.template_dir != null ? var.template_dir : "${path.module}/templates"
}

resource "libvirt_cloudinit_disk" "this" {
  for_each = var.vms

  name = "${each.key}-cloudinit"

  user_data = templatefile(
    "${local.template_dir}/${each.value.os_type}/user-data.yaml.tftpl",
    {
      hostname   = each.value.hostname
      ssh_public = each.value.ssh_public
      networks   = each.value.networks
    }
  )

  meta_data = templatefile(
    "${local.template_dir}/${each.value.os_type}/meta-data.yaml.tftpl",
    {
      hostname = each.value.hostname
    }
  )

  network_config = templatefile(
    "${local.template_dir}/${each.value.os_type}/network-config.yaml.tftpl",
    {
      networks = each.value.networks
    }
  )
}

resource "libvirt_volume" "cloudinit_iso" {
  for_each = var.vms

  name = "${each.key}-cloudinit.iso"
  pool = var.storage_pool

  create = {
    content = {
      url = libvirt_cloudinit_disk.this[each.key].path
    }
  }
}