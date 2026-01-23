
# Módulo `cloudinit`

Gera discos ISO de Cloud-init para máquinas virtuais Linux e VyOS, com base em templates específicos por sistema operacional.

## Responsabilidade

Este módulo:
- Renderiza três arquivos de configuração por VM:
  - `user-data`
  - `meta-data`
  - `network-config`
- Gera um disco temporário com `libvirt_cloudinit_disk`
- Persiste esse disco como volume Libvirt no storage pool especificado (`<vm_name>-cloudinit.iso`)

## O que este módulo **não faz**
- Validar se `os_type` é `"linux"` ou `"vyos"` — falha se o template não existir
- Filtrar VMs por tipo — espera que o chamador já tenha feito isso
- Tratar VMs Windows — elas **não devem ser passadas** para este módulo
- Garantir que os campos de rede estejam completos — essa responsabilidade é dos templates

## Entrada esperada

A variável `vms` deve ser um mapa onde cada VM contém:

| Campo | Tipo | Obrigatório | Observação |
|------|------|-------------|-----------|
| `os_type` | `string` | Sim | Deve ser `"linux"` ou `"vyos"` |
| `hostname` | `string` | Sim | Usado em `meta-data` e `user-data` |
| `ssh_public` | `object` | Sim | Com `type`, `key`, `host_origin` |
| `networks` | `list(object)` | Sim | Mesma estrutura usada em `vm.auto.tfvars` |

> ⚠️ **Requisito crítico**:  
> Os templates devem existir em:  
> - `templates/linux/`  
> - `templates/vyos/`  
> Caso contrário, o Terraform falhará com "template not found".

## Estrutura de templates

O módulo espera os seguintes arquivos:

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

Cada template recebe exatamente os dados fornecidos em `vms[*]`. Portanto, deve tratar campos opcionais (ex: `ipv4_address == null` → configurar DHCP).

## Exemplo de uso

```hcl
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

> **Importante**: o filtro condicional (`if ...`) é **obrigatório** se o mapa original contém VMs Windows.

## Saídas

- `cloudinit_volumes`: mapa indexado pelo nome da VM, contendo:
  - `name`: nome do volume ISO (ex: `"SdnsDMZ01-cloudinit.iso"`)
  - `pool`: nome do storage pool

Essa saída é usada pelo módulo `domain_linux` para anexar o ISO como dispositivo de configuração.

## Limitações conhecidas

- Não suporta múltiplas chaves SSH por VM (apenas um objeto `ssh_public`)
- Não gera ISOs para VMs sem `os_type` válido
- Depende totalmente da correção e robustez dos templates fornecidos
- Não valida semanticamente a configuração de rede antes da renderização
