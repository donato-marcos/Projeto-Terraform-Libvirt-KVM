
# `cloudinit` Module

Generates Cloud-init ISO disks for Linux and VyOS virtual machines, based on OS-specific templates.

## Responsibility

This module:

* Renders three configuration files per VM:

  * `user-data`
  * `meta-data`
  * `network-config`
* Generates a temporary disk using `libvirt_cloudinit_disk`
* Persists this disk as a Libvirt volume in the specified storage pool (`<vm_name>-cloudinit.iso`)

## What this module **does not do**

* Validate whether `os_type` is `"linux"` or `"vyos"` — it will fail if the template does not exist
* Filter VMs by type — expects the caller to handle this
* Handle Windows VMs — they **must not be passed** to this module
* Ensure network fields are complete — this is the responsibility of the templates

## Expected Input

The `vms` variable must be a map where each VM contains:

| Field        | Type           | Required | Notes                                   |
| ------------ | -------------- | -------- | --------------------------------------- |
| `os_type`    | `string`       | Yes      | Must be `"linux"` or `"vyos"`           |
| `hostname`   | `string`       | Yes      | Used in `meta-data` and `user-data`     |
| `ssh_public` | `object`       | Yes      | Includes `type`, `key`, `host_origin`   |
| `networks`   | `list(object)` | Yes      | Same structure used in `vm.auto.tfvars` |

> ⚠️ **Critical requirement**:
> Templates must exist in:
>
> * `templates/linux/`
> * `templates/vyos/`
>   Otherwise, Terraform will fail with "template not found".

## Template Structure

The module expects the following files:

```
templates/
├── linux/
│   ├── user-data.yaml.tftpl
│   ├── meta-data.yaml.tftpl
│   └── network-config.yaml.tftpl
└── vyos/
    ├── user-data.yaml.tftpl
    ├── meta-data.yaml.tftpl
    └── network-config.yaml.tftpl
```

Each template receives exactly the data provided in `vms[*]`. Therefore, it must handle optional fields (e.g., `ipv4_address == null` → configure DHCP).

## Example Usage

```hcl id="q3r8n1"
locals {
  cloudinit_vms = {
    for name, vm in var.vms : name => vm
    if vm.os_type == "linux" || vm.os_type == "vyos"
  }

  cloudinit_input = {
    for name, vm in local.cloudinit_vms : name => {
      os_type    = vm.os_type
      hostname   = name
      ssh_public = var.ssh_public
      networks   = vm.networks
    }
  }
}

module "cloudinit" {
  source       = "../cloudinit"
  vms          = local.cloudinit_input
  storage_pool = var.storage_pool

  depends_on = [module.volume]
}
```

> **Important**: the conditional filter (`if ...`) is **mandatory** if the original map contains Windows VMs.

## Outputs

* `cloudinit_volumes`: map indexed by VM name, containing:

  * `name`: ISO volume name (e.g., `"SdnsDMZ01-cloudinit.iso"`)
  * `pool`: storage pool name

This output is used by the `domain_linux` module to attach the ISO as a configuration device.

## Known Limitations

* Does not support multiple SSH keys per VM (only a single `ssh_public` object)
* Does not generate ISOs for VMs without a valid `os_type`
* Fully depends on the correctness and robustness of the provided templates
* Does not perform semantic validation of network configuration before rendering