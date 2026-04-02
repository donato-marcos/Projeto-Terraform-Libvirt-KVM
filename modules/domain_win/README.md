
# `domain_windows` Module

Creates Windows virtual machines on Libvirt/KVM with configuration optimized for performance and compatibility.

## Responsibility

This module:

* Creates KVM domains with **Hyper-V enlightenments** optimizations
* Automatically attaches the VirtIO driver ISO (`virtio-win-0.1.285.iso`) as a SATA CD-ROM
* Configures the clock to `localtime` (recommended for Windows)
* Enables TPM 2.0 (required for Windows 11, useful for Server 2022+)
* Uses `qxl` video by default for better SPICE integration

## What this module **does not do**

* Use Cloud-init (Windows is not compatible)
* Validate the existence of the `virtio-win-0.1.285.iso` file
* Create the `iso` storage pool — it must already exist
* Automatically install drivers — the ISO is only made available

## Expected Input

| Variable       | Type                     | Notes                               |
| -------------- | ------------------------ | ----------------------------------- |
| `vms`          | `map(object)`            | Only VMs with `os_type = "windows"` |
| `networks_map` | `map({ name = string })` | Output from the `network` module    |
| `volumes_map`  | `map({ name, pool })`    | Output from the `volume` module     |

> ⚠️ **Critical requirement**:
>
> * A **storage pool named `iso`** must exist in Libvirt
> * This pool must contain the file **`virtio-win-0.1.285.iso`**
>   Otherwise, the plan will fail with a missing volume error.

## Hardware Configuration

* **Firmware**: EFI by default
* **CPU**: `host-passthrough` + full *Hyper-V enlightenments*
* **Clock**: `localtime` with `hypervclock` timer enabled
* **Video**: `qxl` with RAM/VGA tuned for graphical performance
* **Disks**: all volumes listed in `disks`, with the one marked `bootable = true` assigned `order = 1`
* **Drivers**: `virtio-win-0.1.285.iso` mounted as a SATA CD-ROM (`sda`)
* **TPM**: always enabled (`tpm-crb`, version 2.0)

## Example Usage

```hcl
locals {
  windows_vms = {
    for name, vm in var.vms : name => vm
    if vm.os_type == "windows"
  }
}

module "domain_win" {
  source       = "../domain_win"
  vms          = local.windows_vms
  networks_map = module.network.networks
  volumes_map  = module.volume.volumes
  storage_pool = var.storage_pool
}
```

## Outputs

* `domains`: map indexed by VM name, containing:

  * `id`: Libvirt domain UUID
  * `name`: VM name

## Known Limitations

* Driver ISO is **hardcoded** as `virtio-win-0.1.285.iso` — cannot be changed without modifying the module
* Does not support fine-grained device customization beyond what is exposed
* Assumes `x86_64` architecture and `q35` machine type
* Requires a preconfigured Windows base image
* Does not support multiple bootable disks (only the first with `bootable = true` gets `order = 1`)