
# Terraform Libvirt Project – Lab Infrastructure

This project provisions a complete virtualized infrastructure using **Terraform + Libvirt/KVM**, designed for **heterogeneous lab environments** with Linux, Windows, and VyOS, supporting IPv4/IPv6 networking.

## 🎯 Objective

Enable **declarative and reproducible** creation of complex topologies — including firewalls, servers, workstations, isolated/NAT networks — with support for:

* Cloud-init for Linux/VyOS (SSH key, static networking, hostname)
* VirtIO drivers for Windows via embedded ISO
* Disks with backing store (base qcow2 images)
* Dual-stack IPv4/IPv6

## 🏗 Architecture

The project is **modular** and **environment-oriented**:

```
terraform-libvirt-project/
├── modules/               # Reusable modules
│   ├── orchestration      # Central orchestrator
│   ├── network            # Libvirt networks (IPv4/IPv6, DHCP, NAT)
│   ├── volume             # Disk volumes (qcow2/raw, backing store)
│   ├── cloudinit          # Cloud-init ISOs (Linux/VyOS)
│   ├── domain_linux       # KVM domains for Linux/VyOS (EFI, TPM, SMM)
│   └── domain_windows     # KVM domains for Windows (Hyper-V, localtime, QXL)
│
└── environments/
    └── lab/               # Example environment (lab)
        ├── *.auto.tfvars.example  # Configuration templates
        └── README.md      # Environment-specific instructions
```

### Execution flow (orchestration)

1. **Networks** → `module.network`
2. **Volumes** → `module.volume` (all disks for all VMs)
3. **Cloud-init** → `module.cloudinit` (**only** if `os_type = ["linux", "vyos"]`)
4. **Linux/VyOS Domains** → `module.domain_linux` (with EFI, TPM, Cloud-init)
5. **Windows Domains** → `module.domain_win` (with Hyper-V, VirtIO drivers, `localtime` clock)

> Each step uses `depends_on` to ensure proper ordering, even without direct references.

## 🚀 How to Use

### Prerequisites

* **Libvirt/KVM** installed and running (`libvirtd`)
* **`default` storage pool** pointing to a directory with base images (e.g., `/home/mdonato/vm`)
* **`iso` storage pool** containing:

  * [`virtio-win-0.1.285.iso`](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.285-1/virtio-win-0.1.285.iso) (required for Windows)
* **Base images** in `image_directory` — the images you need depend on your `vm.auto.tfvars`.  
  Common examples: Ubuntu Cloud, Rocky, custom Win2022, VyOS.
* **Cloud-init templates** in `modules/cloudinit/templates/{linux,vyos}`

### 📋 Which base images do you really need?

**None are universally required.** The images you need depend entirely on the VMs defined in your `vm.auto.tfvars`.

For example, this VM definition:
```json
"SdnsDMZ03" = {
  os_type = "linux"
  disks = [{
    backing_store = {
      image = "ubuntu-24-cloud.x86_64.qcow2"   # <-- THIS image is required
    }
  }]
}
```
*`Requires only ubuntu-24-cloud.x86_64.qcow2`.*

> ✅ **Rule of thumb:** Look at the `backing_store.image` field in each VM definition. Those are the only base images you must provide.

> If your lab doesn't use VyOS, you don't need vyos-custom-image.qcow2.
> If it doesn't use Windows, you don't need win2k22gui-custom-image.qcow2.

> 📖 VyOS users: If your lab includes VyOS, see [Building a VyOS ISO and Base qcow2 Image](https://github.com/donato-marcos/Build-Images/blob/main/build-vyos-custom-qcow2.md) if you need a custom VyOS base image.

### Step-by-step

1. Clone the repository
2. Navigate to the environment:

   ```bash
   cd environments/lab
   ```
3. Copy the templates:

   ```bash
   cp *.auto.tfvars.example .
   mv vm.auto.tfvars.example vm.auto.tfvars
   mv networks.auto.tfvars.example networks.auto.tfvars
   mv secrets.auto.tfvars.example secrets.auto.tfvars
   ```
4. Edit the files:

   * `secrets.auto.tfvars`: your SSH key, URI, pools
   * `networks.auto.tfvars`: define your networks
   * `vm.auto.tfvars`: declare your VMs
5. Run:

   ```bash
   terraform init
   terraform validate
   terraform apply
   ```

### Useful Outputs

After `apply`, the `provisioned_vms` output provides a structure ready for generating an Ansible inventory:

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

## ⚠️ Limitations and Design Decisions

| Aspect          | Detail                                                                       |
| --------------- | ---------------------------------------------------------------------------- |
| **SSH Key**     | Single global key (not per VM)                                               |
| **Windows**     | Does not use Cloud-init; drivers via fixed CD-ROM (`virtio-win-0.1.285.iso`) |
| **Validation**  | No pre-validation of image or network existence                              |
| **Provider**    | Version **pinned to `= 0.9.1`** of `dmacvicar/libvirt`                       |
| **Scalability** | Designed for labs; not for production                                        |

## 📂 Expected File Structure on Host

```
/home/mdonato/vm/                # image_directory = storage_pool "default"
├── ubuntu-24-cloud.x86_64.qcow2
├── Rocky-10-GenericCloud-Base.latest.x86_64.qcow2
├── win2k22gui-custom-image.qcow2
└── vyos-custom-image.qcow2

/home/mdonato/Downloads/iso     # or another path, as long as consistent
└── virtio-win-0.1.285.iso      # inside the "iso" pool
```
> ⚠️ **Important:** The files shown above are **examples only**.  
> You only need the base images that are actually referenced in your `vm.auto.tfvars` under `backing_store.image`.

## 📚 Module Documentation

Each module includes its own `README.md` with:

* Exact responsibilities
* Actual inputs/outputs
* Technical limitations
* Usage examples

See:

* [`modules/network/README.md`](modules/network/README.md)
* [`modules/volume/README.md`](modules/volume/README.md)
* [`modules/cloudinit/README.md`](modules/cloudinit/README.md)
* [`modules/domain_linux/README.md`](modules/domain_linux/README.md)
* [`modules/domain_windows/README.md`](modules/domain_windows/README.md)
* [`modules/orchestration/README.md`](modules/orchestration/README.md)
* [`environments/lab/README.md`](environments/lab/README.md)

## 🧪 Typical Use Cases

* Security lab (VyOS firewall, DMZ, internal servers)
* Corporate network simulation (AD, DNS, DHCP, Windows/Linux workstations)
* IPv6 study in isolated networks
* Development environment with multiple distributions

## 🛠 Technical Requirements

* Terraform = 1.14.0 or OpenTofu = 1.11.0
* Provider `dmacvicar/libvirt` **= 0.9.1**
* QEMU/KVM with TPM 2.0 support
* SPICE enabled (for graphical console)

---

> This project prioritizes **clarity**, **reproducibility**, and **fidelity to real code** — not generic abstractions.