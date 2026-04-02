# vm.auto.tfvars:
vms = {

  # Servidor kubernetes control-plane
  "k8s-master012" = {
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
        ipv6_address   = "2804:14d:3280:403a::11"
        ipv6_prefix    = 64
        ipv6_gateway   = "fe80::523d:d1ff:fea5:b018"
        dns_servers  = ["2001:4860:4860::8888","2606:4700:4700::111"]
        wait_for_lease = false
      },
      {
        name           = "k8s-cluster2"
        ipv6_address   = "fd00:172:16:200::11"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-storage2"
        ipv6_address   = "fd00:172:16:201::11"
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
        ipv6_address   = "2804:14d:3280:403a::21"
        ipv6_prefix    = 64
        ipv6_gateway   = "fe80::523d:d1ff:fea5:b018"
        dns_servers  = ["2001:4860:4860::8888","2606:4700:4700::111"]
        wait_for_lease = false
      },
      {
        name           = "k8s-cluster2"
        ipv6_address   = "fd00:172:16:200::21"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-storage2"
        ipv6_address   = "fd00:172:16:201::21"
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
        ipv6_address   = "2804:14d:3280:403a::22"
        ipv6_prefix    = 64
        ipv6_gateway   = "fe80::523d:d1ff:fea5:b018"
        dns_servers  = ["2001:4860:4860::8888","2606:4700:4700::111"]
        wait_for_lease = false
      },
      {
        name           = "k8s-cluster2"
        ipv6_address   = "fd00:172:16:200::22"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-storage2"
        ipv6_address   = "fd00:172:16:201::22"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  }
}