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
  }

  # --- Features ---
  features = {
    acpi    = true
    apic    = { eoi = "on" }
    smm     = { state = "on" }
    vm_port = { state = "off" }
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

    # --- Console ---
    consoles = [{
      type   = "pty"
      target = { type = "serial" }
    }]

    # --- Canais ---
    channels = (
      each.value.running == true || each.value.graphics == "spice"
    ) ? concat(
      each.value.running == true ? [{
        source = { unix = { mode = "bind" } }
        target = {
          type    = "virtio"
          virt_io = { name = "org.qemu.guest_agent.0" }
        }
      }] : [],
      each.value.graphics == "spice" ? [{
        source = { spice_vmc = true }
        target = { virt_io = { name = "com.redhat.spice.0" } }
      }] : []
    ) : null

    # --- Controllers ---
    controllers = [ {
      type = "scsi"
      model = "virtio-scsi"
      driver = { queues = max(1, floor(each.value.vcpus / 2)) }
    } ]

    # --- Inputs ---
    inputs = each.value.graphics != "none" ? [{
      type = "tablet"
      bus  = "usb"
    }] : null

    # --- TPM ---
    tpms = each.value.firmware == "efi" ? [{
      model = "tpm-crb"
      backend = {
        emulator = { version = "2.0" }
      }
    }] : null

    # --- Gráficos ---
    graphics = each.value.graphics == "none" ? null : (
      each.value.graphics != "vnc" ? [{
        spice = {
          auto_port = true
          image = { compression = "off" }
        }
        vnc = null
      }] : [{
        vnc = {
          auto_port = true
          listen = "127.0.0.1"
        }
        spice = null
      }]
    )

    # --- Áudio ---
    sounds = each.value.graphics != "none" ? [{
      model = "ich9" 
    }] : null

    # --- Vídeo ---
    videos = ( each.value.video_model != "none" && each.value.graphics != "none" ) ? [{
      model = {
        type    = each.value.video_model
        primary = "yes"
        heads   = 1
      }
    }] : null

    vsock = {
      cid = {
        auto = "yes"
      }
    }

    # --- Redirecionamento USB ---
    redir_devs = each.value.graphics == "spice" ? [
      {
        bus = "usb"
        source = { spice_vmc = true }
      },
      {
        bus = "usb"
        source = { spice_vmc = true }
      }
    ] : null

    # --- RNG ---
    rngs = [{
      model   = "virtio"
      backend = { random = "/dev/urandom" }
    }]
  }

}