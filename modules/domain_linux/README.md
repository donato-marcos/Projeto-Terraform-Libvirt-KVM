
# `domain_linux` Module

Creates Linux and VyOS virtual machines on Libvirt/KVM with configuration optimized for lab environments.

## Responsibility

This module:

* Creates KVM domains with EFI firmware and TPM 2.0
* Attaches disks previously created by the `volume` module
* Mounts a Cloud-init ISO (if available) as a SATA CD-ROM
* Configures network interfaces with support for DHCP lease waiting (`wait_for_lease`)
* Enables the QEMU Guest Agent when the VM is running (`running = true`)

## What this module **does not do**

* Create volumes or networks — it fully depends on the `volume` and `network` modules
* Validate whether the Cloud-init ISO exists — it is only attached if present in `cloudinit_volumes_map`
* Handle Windows VMs — this module must be called **only with `os_type = "linux"` or `"vyos"`**
* Define IP addressing — this is handled via Cloud-init or DHCP

## Expected Input

| Variable                | Type                     | Notes                                         |
| ----------------------- | ------------------------ | --------------------------------------------- |
| `vms`                   | `map(object)`            | Only VMs with `os_type = "linux"` or `"vyos"` |
| `networks_map`          | `map({ name = string })` | Output from the `network` module              |
| `volumes_map`           | `map({ name, pool })`    | Output from the `volume` module               |
| `cloudinit_volumes_map` | `map({ name, pool })`    | Output from the `cloudinit` module            |

> ⚠️ **Critical requirement**:
> Keys in `volumes_map` must follow the pattern `<vm_name>-<disk_name>`.
> Networks referenced in `vms[*].networks[].name` must exist in `networks_map`.

## Hardware Configuration

* **Firmware**: EFI by default, but VyOS must use `bios`
* **TPM**: enabled (`tpm-crb`, version 2.0)
* **CPU**: `host-passthrough`
* **Clock**: UTC, with optimized timers
* **Video**: `virtio` (default), configurable via `video_model`
* **Channels**: SPICE + QEMU Guest Agent (if `running = true`)
* **Disks**: all volumes listed in `disks`, with the one marked `bootable = true` assigned `order = 1`
* **Cloud-init**: attached as a SATA CD-ROM (`sda`) **only if present in `cloudinit_volumes_map`**

## Example Usage

```hcl
locals {
  linux_vyos_vms = {
    for name, vm in var.vms : name => vm
    if vm.os_type == "linux" || vm.os_type == "vyos"
  }
}

module "domain_linux" {
  source                = "../domain_linux"
  vms                   = local.linux_vyos_vms
  networks_map          = module.network.networks
  volumes_map           = module.volume.volumes
  cloudinit_volumes_map = module.cloudinit.cloudinit_volumes
  storage_pool          = var.storage_pool
}
```

## Outputs

* `domains`: map indexed by VM name, containing:

  * `id`: Libvirt domain UUID
  * `name`: VM name

## Known Limitations

* Does not support multiple bootable disks (only the first with `bootable = true` gets `order = 1`)
* Assumes `x86_64` architecture and `q35` machine type
* Does not allow fine-grained device customization beyond what is exposed (e.g., serial, USB)
* Requires all Cloud-init templates to be present and functional