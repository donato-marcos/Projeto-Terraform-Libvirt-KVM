output "volumes" {
  description = "Mapa de volumes criados, indexados por '<vm_name>-<disk_name>'"
  value = {
    for k, vol in libvirt_volume.this : k => {
      id   = vol.id
      name = vol.name
      pool = vol.pool
    }
  }
}