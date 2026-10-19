# networks.auto.tfvars:
networks = [
  {
    name      = "talos-mgmt"
    mode      = "isolated"
    autostart = true

    ipv4_address      = null
    ipv4_prefix       = null
    ipv4_dhcp_enabled = false
    #ipv4_dhcp_start   = "172.16.1.10"
    #ipv4_dhcp_end     = "172.16.1.200"
    #dhcp_reservations = [
    #  {
    #    mac  = "52:54:00:10:00:11"
    #    ip   = "172.16.1.11"
    #    name = "talos-cp01"
    #  },
    #  {
    #    mac  = "52:54:00:10:00:12"
    #    ip   = "172.16.1.12"
    #    name = "talos-cp02"
    #  },
    #  {
    #    mac  = "52:54:00:10:00:13"
    #    ip   = "172.16.1.13"
    #    name = "talos-cp03"
    #  },
    #  {
    #    mac  = "52:54:00:10:00:21"
    #    ip   = "172.16.1.21"
    #    name = "talos-worker01"
    #  },
    #  {
    #    mac  = "52:54:00:10:00:22"
    #    ip   = "172.16.1.22"
    #    name = "talos-worker02"
    #  },
    #  {
    #    mac  = "52:54:00:10:00:23"
    #    ip   = "172.16.1.23"
    #    name = "talos-worker03"
    #  },
    #]
    ipv6_address      = null
    ipv6_prefix       = null
    ipv6_dhcp_enabled = false
    #ipv6_dhcp_start   = "fd00:172:16:1::10"
    #ipv6_dhcp_end     = "fd00:172:16:1::200"
  },
  {
    name      = "talos-cluster"
    mode      = "isolated"
    autostart = true

    ipv4_address      = null
    ipv4_prefix       = null
    ipv4_dhcp_enabled = false
    ipv6_address      = null
    ipv6_prefix       = null
    ipv6_dhcp_enabled = false
  },
  {
    name      = "talos-storage"
    mode      = "isolated"
    autostart = true

    ipv4_address      = null
    ipv4_prefix       = null
    ipv4_dhcp_enabled = false
    ipv6_address      = null
    ipv6_prefix       = null
    ipv6_dhcp_enabled = false
  }
]