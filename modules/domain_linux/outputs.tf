output "domains" {
  description = "Mapa de domínios criados"
  value = {
    for k, domain in libvirt_domain.this : k => {
      id   = domain.id
      name = domain.name
    }
  }
}