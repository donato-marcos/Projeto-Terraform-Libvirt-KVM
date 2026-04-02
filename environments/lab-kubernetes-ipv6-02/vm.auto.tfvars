# vm.auto.tfvars:
vms = {

  # Roteador de borda
  "k8s-master012" = {
    os_type     = "vyos"
    vcpus       = 2
    memory      = 1024
    firmware    = "bio"
    video_model = "virtio"
    graphics    = "spice"
    running     = true
    disks = [
      {
        name     = "os"
        size_gb  = 25
        bootable = true

        backing_store = {
          image  = "vyos-custem-image.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "bridge0"
        ipv6_address   = "2804:14d:3280:46c4::10"
        ipv6_prefix    = 64
        wait_for_lease = true
      },
      {
        name           = "k8s-cluster"
        ipv6_address   = "fd00:172:16:200::10"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes control-plane
  "vyos-border01" = {
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
          image  = "ubuntu-24-cloud.x86_64.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
       {
        name           = "bridge0"
        ipv6_address   = "2804:14d:3280:46c4::11"
        ipv6_prefix    = 64
        wait_for_lease = true
      },
      {
        name           = "k8s-cluster"
        ipv6_address   = "fd00:172:16:200::11"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes worker
  "k8s-worker012" = {
    os_type     = "linux"
    vcpus       = 2
    memory      = 8192
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
          image  = "ubuntu-24-cloud.x86_64.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
       {
        name           = "bridge0"
        ipv6_address   = "2804:14d:3280:46c4::21"
        ipv6_prefix    = 64
        wait_for_lease = true
      },
      {
        name           = "k8s-cluster2"
        ipv6_address   = "fd00:172:16:200::21"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes worker
  "k8s-worker022" = {
    os_type     = "linux"
    vcpus       = 2
    memory      = 8192
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
          image  = "ubuntu-24-cloud.x86_64.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
       {
        name           = "bridge0"
        ipv6_address   = "2804:14d:3280:46c4::21"
        ipv6_prefix    = 64
        wait_for_lease = true
      },
      {
        name           = "k8s-cluster2"
        ipv6_address   = "fd00:172:16:200::22"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  }
}