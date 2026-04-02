# vm.auto.tfvars:
vms = {

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
          image  = "ubuntu-24-cloud.x86_64.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name         = "bridge0"
        ipv4_address = "192.168.0.65"
        ipv4_prefix  = 24
        ipv4_gateway = "192.168.0.1"
        dns_servers  = ["192.168.0.1","8.8.8.8"]
        wait_for_lease = false
      },
      {
        name           = "k8s-cluster"
        ipv4_address   = "172.16.200.65"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "172.16.201.65"
        ipv4_prefix    = 24
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes worker
  "k8s-worker01" = {
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
        name         = "bridge0"
        ipv4_address = "192.168.0.66"
        ipv4_prefix  = 24
        ipv4_gateway = "192.168.0.1"
        dns_servers  = ["192.168.0.1","8.8.8.8"]
        wait_for_lease = false
      },
      {
        name           = "k8s-cluster"
        ipv4_address   = "172.16.200.66"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "172.16.201.66"
        ipv4_prefix    = 24
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes worker
  "k8s-worker02" = {
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
        name         = "bridge0"
        ipv4_address = "192.168.0.67"
        ipv4_prefix  = 24
        ipv4_gateway = "192.168.0.1"
        dns_servers  = ["192.168.0.1","8.8.8.8"]
        wait_for_lease = false
      },
      {
        name           = "k8s-cluster"
        ipv4_address   = "172.16.200.67"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "172.16.201.67"
        ipv4_prefix    = 24
        wait_for_lease = false
      }
    ]
  }
}