resource "libvirt_network" "this" {
  for_each = {
    for net in var.networks : net.name => net
  }

  name      = each.value.name
  bridge = {
    name = substr("br-${each.value.name}", 0, 15)
  }
  autostart = each.value.autostart

  forward = each.value.mode != "isolated" ? {
    mode = each.value.mode
  } : null

  domain = {
    name = each.value.name
  }

  ips = concat(
    each.value.ipv4_address != null ? [{
      address = each.value.ipv4_address
      prefix  = each.value.ipv4_prefix
      dhcp = each.value.ipv4_dhcp_enabled ? {
        ranges = [{
          start = each.value.ipv4_dhcp_start
          end   = each.value.ipv4_dhcp_end
        }]
      } : null
    }] : [],
  
    each.value.ipv6_address != null ? [{
      family  = "ipv6"
      address = each.value.ipv6_address
      prefix  = each.value.ipv6_prefix
      dhcp = each.value.ipv6_dhcp_enabled ? {
        ranges = [{
          start = each.value.ipv6_dhcp_start
          end   = each.value.ipv6_dhcp_end
        }]
      } : null
    }] : []
  )

}