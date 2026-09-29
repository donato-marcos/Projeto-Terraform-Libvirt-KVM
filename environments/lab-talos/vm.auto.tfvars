# vm.auto.tfvars:
vms = {
  # BGP Router (VyOS)
  "talos-vyos" = {
    os_type        = "vyos"
    vcpus          = 2
    current_memory = 1024
    memory         = 2048
    firmware       = "bios"
    video_model    = "virtio"
    graphics       = "vnc"
    running        = true
    disks = [
      {
        name     = "os"
        size_gb  = 10 # Em GiB
        bootable = true

        backing_store = {
          image  = "vyos-custom-image.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "bridge0"
        ipv4_address   = "192.168.0.20"
        ipv4_prefix    = 24
        ipv4_gateway   = "192.168.0.1"
        wait_for_lease = true
      },
      {
        name           = "talos-mgmt"
        ipv4_address   = "172.16.1.254"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:1::254"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "talos-cluster"
        ipv4_address   = "172.16.200.254"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::254"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "talos-storage"
        ipv4_address   = "172.16.201.254"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::254"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes control-plane
  "talos-cp01" = {
    os_type        = "talos"
    vcpus          = 2
    current_memory = 5120
    memory         = 5120
    firmware       = "efi"
    video_model    = "virtio"
    graphics       = "spice"
    running        = true
    disks = [
      {
        name     = "os"
        size_gb  = 40
        bootable = true

        backing_store = {
          image  = "talos-1140-nocloud-amd64-secureboot.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name         = "talos-mgmt"
        ipv4_address = "172.16.1.11"
        ipv4_prefix  = 24
        ipv4_gateway = "172.16.1.254"
        #mac_address    = "52:54:00:10:00:11"
        ipv6_address   = "fd00:172:16:1::11"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "talos-cluster"
        ipv4_address   = "172.16.200.11"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::11"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "talos-storage"
        ipv4_address   = "172.16.201.11"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::11"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

#  # Servidor kubernetes control-plane
#  "talos-cp02" = {
#    os_type        = "talos"
#    vcpus          = 2
#    current_memory = 3584
#    memory         = 4096
#    firmware       = "efi"
#    video_model    = "virtio"
#    graphics       = "spice"
#    running        = true
#    disks = [
#      {
#        name     = "os"
#        size_gb  = 40
#        bootable = true
#
#        backing_store = {
#          image  = "talos-1140-nocloud-amd64-secureboot.qcow2"
#          format = "qcow2"
#        }
#      }
#    ]
#    networks = [
#      {
#        name         = "talos-mgmt"
#        ipv4_address = "172.16.1.12"
#        ipv4_prefix  = 24
#        ipv4_gateway = "172.16.1.254"
#        #mac_address    = "52:54:00:10:00:12"
#        ipv6_address   = "fd00:172:16:1::12"
#        ipv6_prefix    = 64
#        ipv6_gateway   = "fd00:172:16:1::254"
#        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
#        wait_for_lease = false
#      },
#      {
#        name           = "talos-cluster"
#        ipv4_address   = "172.16.200.12"
#        ipv4_prefix    = 24
#        ipv6_address   = "fd00:172:16:200::12"
#        ipv6_prefix    = 64
#        wait_for_lease = false
#      },
#      {
#        name           = "talos-storage"
#        ipv4_address   = "172.16.201.12"
#        ipv4_prefix    = 24
#        ipv6_address   = "fd00:172:16:201::12"
#        ipv6_prefix    = 64
#        wait_for_lease = false
#      }
#    ]
#  },
#
#  # Servidor kubernetes control-plane
#  "talos-cp03" = {
#    os_type        = "talos"
#    vcpus          = 2
#    current_memory = 3584
#    memory         = 4096
#    firmware       = "efi"
#    video_model    = "virtio"
#    graphics       = "spice"
#    running        = true
#    disks = [
#      {
#        name     = "os"
#        size_gb  = 40
#        bootable = true
#
#        backing_store = {
#          image  = "talos-1140-nocloud-amd64-secureboot.qcow2"
#          format = "qcow2"
#        }
#      }
#    ]
#    networks = [
#      {
#        name         = "talos-mgmt"
#        ipv4_address = "172.16.1.13"
#        ipv4_prefix  = 24
#        ipv4_gateway = "172.16.1.254"
#        #mac_address    = "52:54:00:10:00:13"
#        ipv6_address   = "fd00:172:16:1::13"
#        ipv6_prefix    = 64
#        ipv6_gateway   = "fd00:172:16:1::254"
#        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
#        wait_for_lease = false
#      },
#      {
#        name           = "talos-cluster"
#        ipv4_address   = "172.16.200.13"
#        ipv4_prefix    = 24
#        ipv6_address   = "fd00:172:16:200::13"
#        ipv6_prefix    = 64
#        wait_for_lease = false
#      },
#      {
#        name           = "talos-storage"
#        ipv4_address   = "172.16.201.13"
#        ipv4_prefix    = 24
#        ipv6_address   = "fd00:172:16:201::13"
#        ipv6_prefix    = 64
#        wait_for_lease = false
#      }
#    ]
#  },

  # Servidor kubernetes worker
  "talos-worker01" = {
    os_type        = "talos"
    vcpus          = 2
    current_memory = 7168
    memory         = 7168
    firmware       = "efi"
    video_model    = "virtio"
    graphics       = "spice"
    running        = true
    disks = [
      {
        name     = "os"
        size_gb  = 60
        bootable = true

        backing_store = {
          image  = "talos-1140-nocloud-amd64-secureboot.qcow2"
          format = "qcow2"
        }
      },
      { name = "data", size_gb = 250, format = "qcow2" }
    ]
    networks = [
      {
        name         = "talos-mgmt"
        ipv4_address = "172.16.1.21"
        ipv4_prefix  = 24
        ipv4_gateway = "172.16.1.254"
        #mac_address    = "52:54:00:10:00:21"
        ipv6_address   = "fd00:172:16:1::21"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "talos-cluster"
        ipv4_address   = "172.16.200.21"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::21"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "talos-storage"
        ipv4_address   = "172.16.201.21"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::21"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes worker
  "talos-worker02" = {
    os_type        = "talos"
    vcpus          = 2
    current_memory = 7168
    memory         = 7168
    firmware       = "efi"
    video_model    = "virtio"
    graphics       = "spice"
    running        = true
    disks = [
      {
        name     = "os"
        size_gb  = 60
        bootable = true

        backing_store = {
          image  = "talos-1140-nocloud-amd64-secureboot.qcow2"
          format = "qcow2"
        }
      },
      { name = "data", size_gb = 250, format = "qcow2" }
    ]
    networks = [
      {
        name         = "talos-mgmt"
        ipv4_address = "172.16.1.22"
        ipv4_prefix  = 24
        ipv4_gateway = "172.16.1.254"
        #mac_address    = "52:54:00:10:00:22"
        ipv6_address   = "fd00:172:16:1::22"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "talos-cluster"
        ipv4_address   = "172.16.200.22"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::22"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "talos-storage"
        ipv4_address   = "172.16.201.22"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::22"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes worker
  "talos-worker03" = {
    os_type        = "talos"
    vcpus          = 2
    current_memory = 7168
    memory         = 7168
    firmware       = "efi"
    video_model    = "virtio"
    graphics       = "spice"
    running        = true
    disks = [
      {
        name     = "os"
        size_gb  = 60
        bootable = true

        backing_store = {
          image  = "talos-1140-nocloud-amd64-secureboot.qcow2"
          format = "qcow2"
        }
      },
      { name = "data", size_gb = 250, format = "qcow2" }
    ]
    networks = [
      {
        name         = "talos-mgmt"
        ipv4_address = "172.16.1.23"
        ipv4_prefix  = 24
        ipv4_gateway = "172.16.1.254"
        #mac_address    = "52:54:00:10:00:23"
        ipv6_address   = "fd00:172:16:1::23"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "talos-cluster"
        ipv4_address   = "172.16.200.23"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::23"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "talos-storage"
        ipv4_address   = "172.16.201.23"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::23"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  }
}