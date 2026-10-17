vms = {
  # Controlador de domínio Windows (AD + DNS + DHCP)
  "SdcSVR03" = {
    os_type     = "windows"
    vcpus       = 3
    memory      = 4096
    running     = true
    video_model = "qxl"
    graphics    = "spice"
    disks = [
      {
        name     = "os"
        size_gb  = 60
        bootable = true

        backing_store = {
          image  = "win2k22gui-custom-image-clone.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name         = "servers-net"
        ipv4_address = "10.20.100.10"
        ipv4_prefix  = 24
        ipv4_gateway = "10.20.100.254"
      }
    ]
  }
}