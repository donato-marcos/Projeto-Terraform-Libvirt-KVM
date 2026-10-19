resource "libvirt_domain" "this" {
  for_each = var.vms

  name                = each.key
  vcpu                = each.value.vcpus
  memory_unit         = "MiB"
  memory              = each.value.memory
  current_memory_unit = "MiB"
  current_memory      = try(each.value.current_memory, each.value.memory)
  running             = try(each.value.running, false)
  type                = "kvm"

  # --- OS ---
  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    firmware     = each.value.firmware == "efi" ? "efi" : null
    loader       = each.value.os_type == "talos" ? "/usr/share/edk2/ovmf/OVMF_CODE.fd" : null
  }

  # --- Features ---
  features = {
    acpi    = true
    apic    = {}
    smm     = { state = "on" }
    vm_port = { state = "off" }
    kvm = {
      poll_control = { state = "on" }
      pvipi = {  state = "on" }
    }
  }

  # --- CPU ---
  cpu = { mode = "host-passthrough" }

  # --- Clock ---
  clock = {
    offset = "utc"
    timer = [
      { name = "rtc", tick_policy = "catchup" },
      { name = "pit", tick_policy = "delay" },
      { name = "hpet", present = "no" }
    ]
  }

  # --- Power Management ---
  pm = {
    suspend_to_mem  = { enabled = "no" }
    suspend_to_disk = { enabled = "no" }
  }

  # --- Devices ---
  devices = {

    # --- Discos ---
    disks = concat(
      [
        # Disco(s) principal(is)
        for i, disk in each.value.disks : {
          driver = {
            name    = "qemu"
            type    = "qcow2"
            discard = "unmap"
            cache   = "none"
            io      = "native"
            #queues  = max(1, floor(each.value.vcpus / 2))
          }
          source = {
            volume = {
              pool   = var.volumes_map["${each.key}-${disk.name}"].pool
              volume = var.volumes_map["${each.key}-${disk.name}"].name
            }
          }
          target = {
            dev = "sd${substr("abcdefghijklmnopqrstuvwxyz", i, 1)}"
            bus = "scsi"
          }
          boot = disk.bootable ? { order = 1 } : null
        }
      ],
      # Disco cloud-init (se existir)
      lookup(var.cloudinit_volumes_map, each.key, null) != null ? [{
        device = "cdrom"
        driver = {
          name = "qemu"
          type = "raw"
        }
        source = {
          volume = {
            pool   = var.cloudinit_volumes_map[each.key].pool
            volume = var.cloudinit_volumes_map[each.key].name
          }
        }
        target = {
          dev = "hda"
          bus = "sata"
        }
      }] : []
    )

    # --- Interfaces ---
    interfaces = [
      for net in each.value.networks : {
        source = (
          startswith(net.name, "bridge") || 
          startswith(net.name, "br")
        ) ? {
          bridge = { bridge = net.name }
        } : {
          network = { network = var.networks_map[net.name].name }
        }
        model = { type = "virtio" }
        driver = {
          name = "vhost"
          queues = each.value.vcpus
        }
        mac = net.mac_address != null ? {
          address = net.mac_address
        } : null
        wait_for_ip = (
          !(startswith(net.name, "bridge") || startswith(net.name, "br")) &&
          net.wait_for_lease
        ) ? {
          timeout = 300
          source  = "lease"
        } : null
      }
    ]

    ## --- Console ---
    #consoles = [{
    #  type   = "pty"
    #  target = { type = "serial" }
    #}]

    # --- Canais ---
    channels = [{
        source = { unix = { mode = "bind" } }
        target = {
          type    = "virtio"
          virt_io = { name = "org.qemu.guest_agent.0" }
        }
      }]

    # --- Controllers ---
    controllers = [
      {
        type = "scsi"
        model = "virtio-scsi"
        driver = { queues = max(1, floor(each.value.vcpus / 2)) }
      },
      {
        type = "usb"
        model = "none"
      }
    ]

    # --- TPM ---
    tpms = each.value.firmware == "efi" ? [{
      model = "tpm-crb"
      backend = {
        emulator = { version = "2.0" }
      }
    }] : null

    # --- Vídeo ---
    videos = [{
      model = {
        type    = "none"
      }
    }]

    vsock = {
      cid = {
        auto = "yes"
      }
    }

    mem_balloon = {
      model = "none"
    }

    # --- RNG ---
    rngs = [{
      model   = "virtio"
      backend = { random = "/dev/urandom" }
    }]
  }

}