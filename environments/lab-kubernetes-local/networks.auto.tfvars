# networks.auto.tfvars:
networks = [
  {
    name      = "k8s-wan"
    mode      = "nat"
    autostart = true

    ipv4_address      = "192.168.49.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = true
    ipv4_dhcp_start   = "192.168.49.10"
    ipv4_dhcp_end     = "192.168.49.200"
  },
  {
    name      = "k8s-external"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "192.168.50.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
  },
  {
    name      = "k8s-mgmt"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "192.168.51.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
  },
  {
    name      = "k8s-control"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "172.16.0.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
  },
  {
    name      = "k8s-data"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "172.16.1.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
  },
  {
    name      = "k8s-storage"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "10.0.0.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
  }
]