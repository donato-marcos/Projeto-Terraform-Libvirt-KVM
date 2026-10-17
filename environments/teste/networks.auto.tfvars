# networks.auto.tfvars

networks = [
  {
    name      = "servers-net"
    mode      = "nat"
    autostart = true

    ipv4_address      = "172.16.254.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = true
    ipv4_dhcp_start   = "172.16.254.10"
    ipv4_dhcp_end     = "172.16.254.200"

    #ipv6_address      = "fd00:172:16:254::1"
    #ipv6_prefix       = 64
    #ipv6_dhcp_enabled = true
    #ipv6_dhcp_start   = "fd00:172:16:254::100"
    #ipv6_dhcp_end     = "fd00:172:16:254::1ff"
  }
]