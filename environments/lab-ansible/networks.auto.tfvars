# networks.auto.tfvars

networks = [
  {
    name      = "wan-net"
    mode      = "nat"
    autostart = true

    ipv4_address      = "172.16.254.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = true
    ipv4_dhcp_start   = "172.16.254.10"
    ipv4_dhcp_end     = "172.16.254.200"
  },
  {
    name      = "uplink-net"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "10.21.1.1"
    ipv4_prefix       = 29
    ipv4_dhcp_enabled = false
  },
  {
    name      = "servers-net"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "10.20.100.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
  },
  {
    name      = "dmz-net"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "10.20.200.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
  },
  {
    name      = "clientes_ti-net"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "10.20.10.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
  },
  {
    name      = "clientes_fin-net"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "10.20.11.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
  }
]