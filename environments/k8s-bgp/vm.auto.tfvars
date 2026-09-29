# vm.auto.tfvars:
vms = {
  # BGP Router (VyOS)
  "k8s-vyos" = {
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
        wait_for_lease = true
      },
      {
        name           = "k8s-mgmt"
        ipv4_address   = "172.16.1.254"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:1::254"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-cluster"
        ipv4_address   = "172.16.200.254"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::254"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "172.16.201.254"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::254"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes control-plane
  "k8s-master01" = {
    os_type     = "linux"
    vcpus       = 2
    memory      = 4096
    firmware    = "efi"
    video_model = "virtio"
    graphics    = "spice"
    running     = true
    disks = [
      {
        name     = "os"
        size_gb  = 25
        bootable = true

        backing_store = {
          image  = "ubuntu-26-cloud.x86_64.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "k8s-mgmt"
        ipv4_address   = "172.16.1.11"
        ipv4_prefix    = 24
        ipv4_gateway   = "172.16.1.254"
        ipv6_address   = "fd00:172:16:1::11"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "k8s-cluster"
        ipv4_address   = "172.16.200.11"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::11"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "172.16.201.11"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::11"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes worker
  "k8s-worker01" = {
    os_type     = "linux"
    vcpus       = 2
    memory      = 6144
    firmware    = "efi"
    video_model = "virtio"
    graphics    = "spice"
    running     = true
    disks = [
      {
        name     = "os"
        size_gb  = 25
        bootable = true

        backing_store = {
          image  = "ubuntu-26-cloud.x86_64.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "k8s-mgmt"
        ipv4_address   = "172.16.1.21"
        ipv4_prefix    = 24
        ipv4_gateway   = "172.16.1.254"
        ipv6_address   = "fd00:172:16:1::21"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "k8s-cluster"
        ipv4_address   = "172.16.200.21"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::21"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "172.16.201.21"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::21"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes worker
  "k8s-worker02" = {
    os_type     = "linux"
    vcpus       = 2
    memory      = 6144
    firmware    = "efi"
    video_model = "virtio"
    graphics    = "spice"
    running     = true
    disks = [
      {
        name     = "os"
        size_gb  = 25
        bootable = true

        backing_store = {
          image  = "ubuntu-26-cloud.x86_64.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "k8s-mgmt"
        ipv4_address   = "172.16.1.22"
        ipv4_prefix    = 24
        ipv4_gateway   = "172.16.1.254"
        ipv6_address   = "fd00:172:16:1::22"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "k8s-cluster"
        ipv4_address   = "172.16.200.22"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::22"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "172.16.201.22"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::22"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  }

  # Servidor kubernetes worker
  "k8s-worker03" = {
    os_type     = "linux"
    vcpus       = 2
    memory      = 6144
    firmware    = "efi"
    video_model = "virtio"
    graphics    = "spice"
    running     = true
    disks = [
      {
        name     = "os"
        size_gb  = 25
        bootable = true

        backing_store = {
          image  = "ubuntu-26-cloud.x86_64.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "k8s-mgmt"
        ipv4_address   = "172.16.1.23"
        ipv4_prefix    = 24
        ipv4_gateway   = "172.16.1.254"
        ipv6_address   = "fd00:172:16:1::23"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "k8s-cluster"
        ipv4_address   = "172.16.200.23"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::23"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "172.16.201.23"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::23"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  }
}