output "networks" {
  description = "Mapa das redes criadas, indexadas pelo nome"
  value = {
    for k, net in libvirt_network.this : k => {
      id     = net.id
      name   = net.name
      bridge = net.bridge
    }
  }
}