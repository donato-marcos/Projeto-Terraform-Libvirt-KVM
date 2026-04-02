
# `volume` Module

Creates Libvirt disk volumes for virtual machines, with or without a base image (*backing store*).

## Responsibility

This module:

* Creates volumes in the specified storage pool (`var.storage_pool`)
* Supports empty disks or disks based on pre-existing images
* Derives the disk format (`qcow2` or `raw`) from the provided configuration
* Names each volume as `<vm_name>-<disk_name>`

## What this module **does not do**

* Validate whether the base image exists in `image_directory`
* Guarantee global uniqueness of volume names (silent collisions may occur if two VMs share the same name + `disk.name`)
* Handle the `bootable` field — it is accepted but **ignored** (responsibility of the domain module)
* Create volumes across multiple pools (all volumes use the same `storage_pool`)

## Expected Input

The `vms` variable must be a map where each VM contains a `disks` list. Each disk supports:

| Field                  | Type     | Required    | Default   | Notes                                                        |
| ---------------------- | -------- | ----------- | --------- | ------------------------------------------------------------ |
| `name`                 | `string` | Yes         | —         | Used to compose the volume name                              |
| `size_gb`              | `number` | Yes         | —         | Size in gibibytes (GiB)                                      |
| `backing_store.image`  | `string` | Conditional | —         | Base image filename (e.g., `"ubuntu-24-cloud.x86_64.qcow2"`) |
| `backing_store.format` | `string` | No          | `"qcow2"` | Base image format                                            |
| `format`               | `string` | No          | `"qcow2"` | Used only if no `backing_store` is defined                   |

> ⚠️ **Critical requirement**:
> The `image_directory` **must physically match** the Libvirt `storage_pool` path.
> Example: if `storage_pool = "default"` points to `/home/user/vm`, then `image_directory` must be `/home/user/vm`.

## Technical Behavior

* **Volume name**: always `<vm_name>-<disk_name>` (e.g., `"SdcSVR01-os"`)
* **Capacity**: internally converted to bytes (`size_gb * 1024³`)
* **Format**: prioritizes `backing_store.format`, then `disk.format`, otherwise `"qcow2"`
* **Backing store**: full path is `${var.image_directory}/${image}`

## Example Usage

```hcl id="l2y2pz"
module "volume" {
  source          = "./modules/volume"
  vms             = var.vms
  image_directory = var.image_directory
  storage_pool    = var.storage_pool
}
```

## Outputs

* `volumes`: map indexed by `<vm_name>-<disk_name>`, containing:

  * `id`: Libvirt volume UUID
  * `name`: volume name
  * `pool`: storage pool name

This output is used by the `domain_linux` and `domain_windows` modules to attach the correct disks.

## Known Limitations

* No pre-validation of base image existence — failures occur only at apply time
* All volumes are created in the same pool (`storage_pool`)
* Long VM + disk names may exceed filesystem limits (rare but possible)
* The `bootable` field is stored in VM data but **does not affect this module**
