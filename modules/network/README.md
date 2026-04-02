
# `network` Module

Creates Libvirt virtual networks with optional support for IPv4 and IPv6, DHCP, and configurable forwarding mode.

## Responsibility

This module:

* Creates Libvirt networks with a dedicated bridge (`br-<name>`, truncated to 15 characters)
* Configures IPv4 **and/or** IPv6 addressing
* Enables DHCP conditionally per protocol
* Defines forwarding mode: `"nat"` or `"isolated"`
* Controls automatic startup (`autostart`)

## What this module **does not do**

* Validate whether the `mode` value is valid (accepts any string; invalid values will cause provider errors)
* Guarantee uniqueness of network names (collisions are not detected)
* Create networks without at least one IP block (IPv4 or IPv6) — this will cause a Libvirt provider failure
* Truncate network names (only the bridge name is truncated)

## Expected Input

The `networks` variable must be a list of objects with the following fields:

| Field                     | Type     | Required             | Default | Notes                                                    |
| ------------------------- | -------- | -------------------- | ------- | -------------------------------------------------------- |
| `name`                    | `string` | Yes                  | —       | Network name; used as identifier and internal DNS domain |
| `mode`                    | `string` | Yes                  | —       | `"nat"` enables forwarding and `"isolated"` disables it  |
| `autostart`               | `bool`   | Yes                  | —       | Whether the network starts with the host                 |
| `ipv4_address`            | `string` | Conditional          | —       | IPv4 network address (e.g., `"192.168.100.1"`)           |
| `ipv4_prefix`             | `number` | If IPv4 enabled      | —       | CIDR prefix (0–32)                                       |
| `ipv4_dhcp_enabled`       | `bool`   | No                   | `false` | Enables IPv4 DHCP                                        |
| `ipv4_dhcp_start` / `end` | `string` | If IPv4 DHCP enabled | —       | Lease range                                              |
| `ipv6_address`            | `string` | Conditional          | —       | IPv6 address (e.g., `"fd00::1"`)                         |
| `ipv6_prefix`             | `number` | If IPv6 enabled      | —       | CIDR prefix (0–128)                                      |
| `ipv6_dhcp_enabled`       | `bool`   | No                   | `false` | Enables IPv6 DHCP                                        |
| `ipv6_dhcp_start` / `end` | `string` | If IPv6 DHCP enabled | —       | Lease range                                              |

> ⚠️ **Critical requirement**:
> At least **one** of the blocks (`ipv4_address` or `ipv6_address`) must be defined.
> Otherwise, the `libvirt_network` resource will fail with "no IP addresses defined".

## Technical Behavior

* **Bridge name**: generated as `br-${name}`, truncated to **15 characters** (Linux kernel limit)
* **Forwarding**: enabled only if `mode != "isolated"`
* **DNS domain**: always set as `name = net.name`
* **DHCP**: included only if `*_dhcp_enabled == true` and `start`/`end` fields are provided

## Example Usage

```hcl
module "network" {
  source   = "./modules/network"
  networks = var.networks
}
```

## Outputs

* `networks`: map indexed by network name, containing:

  * `id`: Libvirt UUID
  * `name`: network name
  * `bridge`: actual bridge interface name created (e.g., `"br-wan"`)

Useful for debugging or integration with other modules (e.g., attaching VM interfaces).

## Known Limitations

* Long network names (>12 characters) result in truncated bridges (e.g., `br-clientes_ti-net` → `br-clientes_ti-`)
* No consistency validation (e.g., IPv4 prefix outside [0,32])
* `"isolated"` mode fully disables forwarding; other modes use Libvirt defaults (`nat`)