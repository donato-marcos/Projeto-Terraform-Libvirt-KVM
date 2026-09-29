# networks.auto.tfvars:
networks = [
  {
    name      = "k8s-wan"
    mode      = "nat"
    autostart = true

    ipv4_address      = "172.16.0.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = true
    ipv4_dhcp_start   = "172.16.0.10"
    ipv4_dhcp_end     = "172.16.0.200"

    ipv6_address      = "fd00:172:16::1"
    ipv6_prefix       = 64
    ipv6_dhcp_enabled = true
    ipv6_dhcp_start   = "fd00:172:16::100"
    ipv6_dhcp_end     = "fd00:172:16::1ff"
  },
  {
    name      = "k8s-mgmt"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "172.16.1.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
    ipv6_address      = "fd00:172:16:1::1"
    ipv6_prefix       = 64
    ipv6_dhcp_enabled = false
  },
  {
    name      = "k8s-cluster"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "172.16.200.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
    ipv6_address      = "fd00:172:16:200::1"
    ipv6_prefix       = 64
    ipv6_dhcp_enabled = false
  },
  {
    name      = "k8s-storage"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "172.16.201.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
    ipv6_address      = "fd00:172:16:201::1"
    ipv6_prefix       = 64
    ipv6_dhcp_enabled = false
  }
]