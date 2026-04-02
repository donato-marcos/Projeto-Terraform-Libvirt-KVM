
# `orchestration` Module

Central orchestrator that coordinates the full creation of Libvirt infrastructure: networks, volumes, Cloud-init, and domains.

## Responsibility

This module:

* Creates all networks defined in `var.networks`
* Provisions disk volumes for **all VMs**, regardless of operating system
* Generates Cloud-init ISOs **only for VMs with `os_type = "linux"` or `"vyos"`**
* Instantiates KVM domains separately:

  * **Linux/VyOS**: with Cloud-init, EFI, and TPM
  * **Windows**: with VirtIO drivers, Hyper-V enlightenments, and `localtime` clock

## What this module **does not do**

* Validate whether networks referenced in VMs exist in `var.networks`
* Customize SSH keys per VM (uses a single global key via `var.ssh_public`)
* Handle missing base image errors (delegated to the `volume` and `domain_*` modules)
* Perform post-provisioning (e.g., Ansible) — infrastructure only

## Internal Flow

The orchestrator executes modules in the following order, with explicit dependencies:

1. **`module.network`** → creates Libvirt networks
2. **`module.volume`** → creates all disks (`<vm>-<disk>`)
3. **`module.cloudinit`** → generates ISOs for Linux/VyOS only
4. **`module.domain_linux`** → instantiates Linux/VyOS VMs with Cloud-init
5. **`module.domain_win`** → instantiates Windows VMs with driver ISO

Each step uses `depends_on` to guarantee ordering, even when there are no direct references.

## Expected Inputs

| Variable          | Type           | Notes                                                        |
| ----------------- | -------------- | ------------------------------------------------------------ |
| `networks`        | `list(object)` | Network definitions (IPv4/IPv6, DHCP, mode)                  |
| `vms`             | `any`          | All VMs, including `os_type`, disks, networks                |
| `ssh_public`      | `object`       | Global SSH key for Cloud-init (`type`, `key`, `host_origin`) |
| `storage_pool`    | `string`       | Libvirt pool for volumes and ISOs                            |
| `image_directory` | `string`       | Physical path to base images                                 |

> ⚠️ **Critical requirement**:
>
> * Networks referenced in `vms[*].networks[].name` **must exist** in `var.networks`

## Outputs

* `provisioned_vms`: consolidated structure containing:

  * Original VM configuration (`os_type`, `vcpus`, etc.)
  * Actual volume names (`vol_name = "<vm>-<disk>"`)
  * Desired state (`"running"` or `"shut off"`)
  * Configured networks (with or without static IP)

Example output:

```json id="s7x7np"
  "SdnsDMZ03" = {
    "current_memory" = 2048
    "disks" = [
      {
        "bootable" = true
        "size_gb" = 50
        "vol_name" = "SdnsDMZ03-os"
      },
    ]
    "memory" = 2048
    "networks" = [
      {
        "dns_servers" = [
          "10.20.100.10",
          "10.20.200.10",
        ]
        "ipv4_address" = "10.20.200.10"
        "ipv4_gateway" = "10.20.200.254"
        "ipv4_prefix" = 24
        "name" = "dmz-net"
      },
    ]
    "os_type" = "linux"
    "running" = true
    "status" = "running"
    "vcpus" = 1
  }
```

## Known Limitations

* Does not support multiple SSH keys per VM
* Does not validate network topology before apply
* Assumes `image_directory` physically matches the `storage_pool`
* Requires Cloud-init templates to exist for the specified `os_type`
* Does not support native `count` or loops — each VM must have a unique key in the map