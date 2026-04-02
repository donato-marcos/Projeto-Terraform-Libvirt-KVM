vms = {
  # Firewall (VyOS)
  "Nfirewall03" = {
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
        name           = "wan-net"
        wait_for_lease = true
      },
      {
        name           = "uplink-net"
        ipv4_address   = "10.21.1.2"
        ipv4_prefix    = 29
        wait_for_lease = false
      }
    ]
  },

  # Roteador (VyOS)
  "Ncore03" = {
    os_type     = "vyos"
    vcpus       = 2
    memory      = 2048
    firmware    = "bios"
    video_model = "virtio"
    graphics    = "vnc"
    running     = true
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
        name           = "uplink-net"
        ipv4_address   = "10.21.1.3"
        ipv4_prefix    = 29
        ipv4_gateway   = "10.21.1.2"
        wait_for_lease = false
      },
      {
        name           = "dmz-net"
        ipv4_address   = "10.20.200.254"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "servers-net"
        ipv4_address   = "10.20.100.254"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "clientes_ti-net"
        ipv4_address   = "10.20.10.254"
        ipv4_prefix    = 24
        wait_for_lease = false
      },
      {
        name           = "clientes_fin-net"
        ipv4_address   = "10.20.11.254"
        ipv4_prefix    = 24
        wait_for_lease = false
      }
    ]
  },
#
#  # Servidor DNS Bind9 na rede DMZ
#  "SdnsDMZ03" = {
#    os_type     = "linux"
#    vcpus       = 1
#    memory      = 1024
#    firmware    = "efi"
#    video_model = "virtio"
#    graphics    = "vnc"
#    running     = true
#    disks = [
#      {
#        name     = "os"
#        size_gb  = 25
#        bootable = true
#
#        backing_store = {
#          image  = "ubuntu-24-cloud.x86_64.qcow2"
#          format = "qcow2"
#        }
#      }
#    ]
#    networks = [
#      {
#        name         = "dmz-net"
#        ipv4_address = "10.20.200.10"
#        ipv4_prefix  = 24
#        ipv4_gateway = "10.20.200.254"
#        dns_servers  = ["8.8.8.8"]
#      }
#    ]
#  },
#
#  # Servidor WEB Nginx na rede DMZ
#  "SwebDMZ03" = {
#    os_type     = "linux"
#    vcpus       = 1
#    memory      = 1024
#    firmware    = "efi"
#    video_model = "virtio"
#    graphics    = "vnc"
#    running     = true
#    disks = [
#      {
#        name     = "os"
#        size_gb  = 25
#        bootable = true
#
#        backing_store = {
#          image  = "Rocky-10-GenericCloud-Base.latest.x86_64.qcow2"
#          format = "qcow2"
#        }
#      }
#    ]
#    networks = [
#      {
#        name         = "dmz-net"
#        ipv4_address = "10.20.200.20"
#        ipv4_prefix  = 24
#        ipv4_gateway = "10.20.200.254"
#        dns_servers  = ["8.8.8.8"]
#      }
#    ]
#  },
#
  # Ansible Manager
  "SansibleSVR03" = {
    os_type     = "linux"
    vcpus       = 2
    memory      = 2048
    firmware    = "efi"
    video_model = "virtio"
    graphics    = "vnc"
    running     = true
    disks = [
      {
        name     = "os"
        size_gb  = 20
        bootable = true

        backing_store = {
          image  = "Fedora-Cloud-Base-Generic-42-1.1.x86_64.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name         = "servers-net"
        ipv4_address = "10.20.100.20"
        ipv4_prefix  = 24
        ipv4_gateway = "10.20.100.254"
        dns_servers  = ["8.8.8.8"]
      }
    ]
  },

#  # Controlador de domínio Windows (AD + DNS + DHCP)
#  "SdcSVR03" = {
#    os_type     = "windows"
#    vcpus       = 4
#    memory      = 6144
#    firmware    = "efi"
#    video_model = "qxl"
#    graphics    = "vnc"
#    running     = true
#    disks = [
#      {
#        name     = "os"
#        size_gb  = 60
#        bootable = true
#
#        backing_store = {
#          image  = "win2k22gui-custom-image.qcow2"
#          format = "qcow2"
#        }
#      }
#    ]
#    networks = [
#      {
#        name         = "servers-net"
#        ipv4_address = "10.20.100.10"
#        ipv4_prefix  = 24
#        ipv4_gateway = "10.20.100.254"
#        dns_servers  = ["10.20.100.10"]
#      }
#    ]
#  },
#  #
#  #  # Estação de trabalho Linux (TI)
#  #  "ClinuxTI03" = {
#  #    os_type = "linux"
#  #    vcpus   = 2
#  #    memory  = 2048
#  #    disks = [
#  #      {
#  #        name     = "os"
#  #        size_gb  = 60
  #        bootable = true
  #  
  #        backing_store = {
  #          image  = "fedoraKDE-custom-image.qcow2"
  #          format = "qcow2"
  #        }
  #      }
  #    ]
  #    networks = [
  #      {
  #        name           = "clientes_ti-net"
  #        wait_for_lease = false
  #      }
  #    ]
  #  },
  #
  #  # Estação de trabalho Windows (FIN)
  #  "CwinFIN03" = {
  #    os_type     = "windows"
  #    vcpus       = 4
  #    memory      = 4096
  #    video_model = "qxl"
  #    disks = [
  #      {
  #        name     = "os"
  #        size_gb  = 60
  #        bootable = true
  #  
  #        backing_store = {
  #          image  = "win10-custom.qcow2"
  #          format = "qcow2"
  #        }
  #      }
  #    ]
  #    networks = [
  #      {
  #        name           = "clientes_fin-net"
  #        wait_for_lease = false
  #      }
  #    ]
  #  }
}