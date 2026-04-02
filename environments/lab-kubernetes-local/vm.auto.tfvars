# vm.auto.tfvars:
vms = {

  # Roteador de borda
  "vyos-border" = {
    os_type        = "vyos"
    vcpus          = 2
    current_memory = 1024
    memory         = 2048
    firmware       = "bios"
    video_model    = "virtio"
    graphics       = "spice"
    running        = true
    disks = [
      {
        name     = "os"
        size_gb  = 10
        bootable = true

        backing_store = {
          image  = "vyos-custom-image.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "k8s-wan"
        wait_for_lease = true
      },
      {
        name           = "k8s-external"
        ipv4_address   = "192.168.50.254"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-mgmt"
        ipv4_address   = "192.168.51.254"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-control"
        ipv4_address   = "172.16.0.254"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-data"
        ipv4_address   = "172.16.1.254"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "10.0.0.254"
        ipv4_prefix    = 24
        wait_for_lease = false
      }
    ]
  },


  # Servidor kubernetes control-plane
  "k8s-master01-teste" = {
    os_type        = "linux"
    vcpus          = 2
    current_memory = 2560
    memory         = 3072
    firmware       = "efi"
    video_model    = "virtio"
    graphics       = "spice"
    running        = true
    disks = [
      {
        name     = "os"
        size_gb  = 25
        bootable = true

        backing_store = {
          image  = "ubuntu-24-cloud.x86_64.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "k8s-external"
        ipv4_address   = "192.168.50.65"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-mgmt"
        ipv4_address   = "192.168.51.65"
        ipv4_prefix    = 24
        ipv4_gateway   = "192.168.51.254"
        wait_for_lease = false
      },
      {
        name           = "k8s-control"
        ipv4_address   = "172.16.0.65"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-data"
        ipv4_address   = "172.16.1.65"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "10.0.0.65"
        ipv4_prefix    = 24
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes worker
  "k8s-worker01-teste" = {
    os_type        = "linux"
    vcpus          = 2
    current_memory = 3072
    memory         = 4096
    firmware       = "efi"
    video_model    = "virtio"
    graphics       = "spice"
    running        = true
    disks = [
      {
        name     = "os"
        size_gb  = 25
        bootable = true

        backing_store = {
          image  = "ubuntu-24-cloud.x86_64.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "k8s-external"
        ipv4_address   = "192.168.50.71"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-mgmt"
        ipv4_address   = "192.168.51.71"
        ipv4_prefix    = 24
        ipv4_gateway   = "192.168.51.254"
        wait_for_lease = false
      },
      {
        name           = "k8s-control"
        ipv4_address   = "172.16.0.71"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-data"
        ipv4_address   = "172.16.1.71"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "10.0.0.71"
        ipv4_prefix    = 24
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes worker
  "k8s-worker02-teste" = {
    os_type        = "linux"
    vcpus          = 2
    current_memory = 3072
    memory         = 4096
    firmware       = "efi"
    video_model    = "virtio"
    graphics       = "spice"
    running        = true
    disks = [
      {
        name     = "os"
        size_gb  = 25
        bootable = true

        backing_store = {
          image  = "ubuntu-24-cloud.x86_64.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "k8s-external"
        ipv4_address   = "192.168.50.72"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-mgmt"
        ipv4_address   = "192.168.51.72"
        ipv4_prefix    = 24
        ipv4_gateway   = "192.168.51.254"
        wait_for_lease = false
      },
      {
        name           = "k8s-control"
        ipv4_address   = "172.16.0.72"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-data"
        ipv4_address   = "172.16.1.72"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "10.0.0.72"
        ipv4_prefix    = 24
        wait_for_lease = false
      }
    ]
  },
  
  # Storage TrueNAS
  "str-truenas01" = {
    os_type        = "truenas"
    vcpus          = 2
    current_memory = 8192
    memory         = 8192
    firmware       = "efi"
    video_model    = "virtio"
    graphics       = "spice"
    running        = true
    disks = [
      {
        name     = "os"
        size_gb  = 16
        bootable = true

        backing_store = {
          image  = "truenas-custom-image.qcow2"
          format = "qcow2"
        }
      },
      { name = "data01", size_gb = 50, format = "qcow2" },
      { name = "data02", size_gb = 50, format = "qcow2" },
      { name = "data03", size_gb = 50, format = "qcow2" }
    ]
    networks = [
      {
        name           = "k8s-mgmt"
        ipv4_address   = "192.168.50.101"
        ipv4_prefix    = 24
        ipv4_gateway   = "192.168.50.254"
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "10.0.0.101"
        ipv4_prefix    = 24
        wait_for_lease = false
      }
    ]
  }
}