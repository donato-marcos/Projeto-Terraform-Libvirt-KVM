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
    hyper_v = {
      mode    = "custom"
      relaxed = { state = "on" }
      vapic   = { state = "on" }
      #spinlocks = { state   = "on", retries = 8191 }
      vp_index = { state = "on" }
      runtime  = { state = "on" }
      synic    = { state = "on" }
      #stimer = { state = "on" }
      frequencies = { state = "on" }
      #tlb_flush = { state = "on" }
      ipi   = { state = "on" }
      #evmcs = { state = "on" }
      avic  = { state = "on" }
    }
  }

  # --- CPU ---
  cpu = { mode = "host-passthrough" }

  # --- Clock ---
  clock = {
    offset = "localtime"
    timer = [
      { name = "rtc", tick_policy = "catchup" },
      { name = "pit", tick_policy = "delay" },
      { name = "hpet", present = "no" },
      { name = "hypervclock", present = "yes" }
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
          }
          source = {
            volume = {
              pool   = var.volumes_map["${each.key}-${disk.name}"].pool
              volume = var.volumes_map["${each.key}-${disk.name}"].name
            }
          }
          target = {
            dev = "vd${substr("abcdefghijklmnopqrstuvwxyz", i, 1)}"
            bus = "virtio"
          }
          boot = disk.bootable ? { order = 1 } : null
        }
      ],
      [{
        device = "cdrom"
        driver = {
          name = "qemu"
          type = "raw"
        }
        source = {
          volume = {
            pool   = "iso"
            volume = "virtio-win-0.1.285.iso"
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      }]
    )

    # --- Interfaces ---
    interfaces = [
      for net in each.value.networks : {
        source = {
          network = {
            network = var.networks_map[net.name].name
          }
        }
        model = { type = "virtio" }
        wait_for_ip = net.wait_for_lease ? {
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
      each.value.running == true || each.value.graphics != "vnc"
    ) ? concat(
      each.value.running == true ? [{
        source = { unix = { mode = "bind" } }
        target = {
          type    = "virtio"
          virt_io = { name = "org.qemu.guest_agent.0" }
        }
      }] : [],
      each.value.graphics != "vnc" ? [{
        source = { spice_vmc = true }
        target = { virt_io = { name = "com.redhat.spice.0" } }
      }] : []
    ) : null

    # --- Inputs ---
    inputs = [{
      type = "tablet"
      bus  = "usb"
    }]

    # --- TPM  ---qxl
    tpms = each.value.firmware == "efi" ? [{
      model = "tpm-crb"
      backend = {
        emulator = { version = "2.0" }
      }
    }] : null

    # --- Gráficos ---
    graphics = each.value.graphics != "vnc" ? [{
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

    # --- Áudio ---
    sounds = [{ model = "ich9" }]

    # --- Vídeo ---
    videos = [{
      model = {
        type    = each.value.video_model
        primary = "yes"
        heads   = 1
        ram     = "65536"
        vram    = "65536"
        vga_mem = "16384"
      }
    }]

    # --- Redirecionamento USB ---
    redir_devs = each.value.graphics != "vnc" ? [
      {
        bus = "usb"
        source = { spice_vmc = true }
      },
      {
        bus = "usb"
        source = { spice_vmc = true }
      }
    ] : null
  }
}