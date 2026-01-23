variable "networks" {
  description = "Lista de configurações de redes a serem criadas"
  type = list(object({
    name      = string
    mode      = string
    autostart = bool

    # --- IPv4 ---
    ipv4_address      = optional(string)
    ipv4_prefix       = optional(number)
    ipv4_dhcp_enabled = optional(bool, false)
    ipv4_dhcp_start   = optional(string)
    ipv4_dhcp_end     = optional(string)

    # --- IPv6 ---
    ipv6_address      = optional(string)
    ipv6_prefix       = optional(number)
    ipv6_dhcp_enabled = optional(bool, false)
    ipv6_dhcp_start   = optional(string)
    ipv6_dhcp_end     = optional(string)
  }))
}