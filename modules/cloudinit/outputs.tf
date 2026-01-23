output "cloudinit_volumes" {
  description = "Mapa de discos cloud-init gerados, indexados pelo nome da VM"
  value = {
    for k, vol in libvirt_volume.cloudinit_iso : k => {
      name = vol.name
      pool = vol.pool
    }
  }
}