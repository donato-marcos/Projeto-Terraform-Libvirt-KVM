networks = [
  {
    name      = "k8s-cluster2"
    mode      = "isolated"
    autostart = true

    ipv6_address      = "fd00:172:16:200::1"
    ipv6_prefix       = 64
    ipv6_dhcp_enabled = false
  },
  {
    name      = "k8s-storage2"
    mode      = "isolated"
    autostart = true

    ipv6_address      = "fd00:172:16:201::1"
    ipv6_prefix       = 64
    ipv6_dhcp_enabled = false
  }
]