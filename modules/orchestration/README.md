
# Módulo `orchestration`

Orquestrador central que coordena a criação completa da infraestrutura Libvirt: redes, volumes, Cloud-init e domínios.

## Responsabilidade

Este módulo:
- Cria todas as redes definidas em `var.networks`
- Provisiona volumes de disco para **todas as VMs**, independentemente do sistema operacional
- Gera ISOs de Cloud-init **apenas para VMs com `os_type = "linux"` ou `"vyos"`**
- Instancia domínios KVM separadamente:
  - **Linux/VyOS**: com Cloud-init, EFI e TPM
  - **Windows**: com drivers VirtIO, Hyper-V enlightenments e relógio em `localtime`

## O que este módulo **não faz**
- Validar se redes referenciadas nas VMs existem em `var.networks`
- Personalizar chaves SSH por VM (usa uma única chave global via `var.ssh_public`)
- Tratar erros de imagem base ausente (delegado aos módulos `volume` e `domain_*`)
- Executar pós-provisionamento (ex: Ansible) — apenas infraestrutura

## Fluxo interno

O orquestrador executa os módulos na seguinte ordem, com dependências explícitas:

1. **`module.network`** → cria redes Libvirt  
2. **`module.volume`** → cria todos os discos (`<vm>-<disk>`)  
3. **`module.cloudinit`** → gera ISOs apenas para Linux/VyOS  
4. **`module.domain_linux`** → instancia VMs Linux/VyOS com Cloud-init  
5. **`module.domain_win`** → instancia VMs Windows com ISO de drivers  

As etapas usam `depends_on` para garantir ordem, mesmo quando não há referência direta.

## Entradas esperadas

| Variável | Tipo | Observação |
|--------|------|-----------|
| `networks` | `list(object)` | Definição de redes (IPv4/IPv6, DHCP, modo) |
| `vms` | `any` | Todas as VMs, com `os_type`, discos, redes |
| `ssh_public` | `object` | Chave SSH global para Cloud-init (`type`, `key`, `host_origin`) |
| `storage_pool` | `string` | Pool Libvirt para volumes e ISOs |
| `image_directory` | `string` | Caminho físico das imagens base |

> ⚠️ **Requisito crítico**:
> - Redes referenciadas em `vms[*].networks[].name` **devem existir** em `var.networks`

## Saídas

- `provisioned_vms`: estrutura consolidada com:
  - Configuração original da VM (`os_type`, `vcpus`, etc.)
  - Nome real dos volumes (`vol_name = "<vm>-<disk>"`)
  - Status desejado (`"running"` ou `"shut off"`)
  - Redes configuradas (com ou sem IP estático)

Exemplo de saída:
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

## Limitações conhecidas

- Não suporta múltiplas chaves SSH por VM
- Não valida topologia de rede antes da aplicação
- Assume que `image_directory` corresponde fisicamente ao `storage_pool`
- Requer que templates de Cloud-init existam para `os_type` usado
- Não suporta `count` ou loops nativos — cada VM deve ter chave única no mapa