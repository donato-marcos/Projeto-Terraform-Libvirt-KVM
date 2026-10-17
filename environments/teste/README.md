
# `lab` Environment

Terraform entry point for provisioning lab infrastructure using Libvirt/KVM.

## Responsibility

This environment:

* Configures the Libvirt provider with a customizable URI (`qemu:///system` by default)
* Loads infrastructure variables and secrets via `.auto.tfvars` files
* Invokes the `orchestration` module to create the entire infrastructure
* Does not create resources directly — delegates everything to the orchestrator

## Expected File Structure

After cloning the repository, create the following files from the templates:

```bash
cd environments/lab
cp vm.auto.tfvars.example vm.auto.tfvars
cp networks.auto.tfvars.example networks.auto.tfvars
cp secrets.auto.tfvars.example secrets.auto.tfvars
```

### Required Files

| File                   | Purpose                                                        |
| ---------------------- | -------------------------------------------------------------- |
| `secrets.auto.tfvars`  | Public SSH key, Libvirt URI, storage pool, and base image path |
| `networks.auto.tfvars` | Network definitions (NAT, isolated, IPv4/IPv6, DHCP)           |
| `vm.auto.tfvars`       | Full specification of each VM (Linux, Windows, VyOS)           |

> ⚠️ **Critical requirement**:
>
> * `storage_pool` and `image_directory` must point to the **same physical directory**
> * The `iso` storage pool must exist and contain [`virtio-win-0.1.285.iso`](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.285-1/virtio-win-0.1.285.iso) (for Windows VMs)

## Execution Flow

```bash
cd environments/lab
terraform init
terraform validate
terraform apply
```

The plan will create:

* Virtual networks
* Disk volumes (with or without backing store)
* Cloud-init ISOs (Linux/VyOS only)
* KVM domains (with OS-specific configurations)

## Useful Outputs

The `provisioned_vms` output provides a consolidated view of the created infrastructure, ideal for generating an Ansible inventory:

```json
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

* Does not validate the existence of base images before apply
* Does not check for existing networks
* Does not verify whether networks referenced in VMs are defined in `networks.auto.tfvars`
* Requires all Cloud-init templates to be present in the correct directories
* Libvirt provider version is pinned to `= 0.9.1` (not compatible with older versions without adjustments)

## Typical Use Case

This environment is designed for:

* Study labs (networking, security, automation)
* Simulation of topologies with firewalls, servers, and workstations
* Heterogeneous environments (Linux, Windows, VyOS)
* Dual-stack IPv4/IPv6 testing

Supports:

* Disks with backing store (qcow2 base images)
* Isolated and NAT networks
* Cloud-init for Linux/VyOS
* VirtIO drivers for Windows via CD-ROM