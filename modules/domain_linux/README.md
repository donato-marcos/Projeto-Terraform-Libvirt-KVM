
# Módulo `domain_linux`

Cria máquinas virtuais Linux e VyOS no Libvirt/KVM com configuração otimizada para laboratórios.

## Responsabilidade

Este módulo:
- Cria domínios KVM com firmware EFI e TPM 2.0
- Anexa discos previamente criados pelo módulo `volume`
- Monta ISO de Cloud-init (se disponível) como CD-ROM SATA
- Configura interfaces de rede com suporte a espera por DHCP (`wait_for_lease`)
- Ativa QEMU Guest Agent quando a VM está em execução (`running = true`)

## O que este módulo **não faz**
- Criar volumes ou redes — depende totalmente dos módulos `volume` e `network`
- Validar se o ISO de Cloud-init existe — anexa apenas se presente em `cloudinit_volumes_map`
- Tratar VMs Windows — este módulo deve ser chamado **apenas com `os_type = "linux"` ou `"vyos"`**
- Definir endereçamento IP — isso é feito via Cloud-init ou DHCP

## Entrada esperada

| Variável | Tipo | Observação |
|--------|------|-----------|
| `vms` | `map(object)` | Apenas VMs com `os_type = "linux"` ou `"vyos"` |
| `networks_map` | `map({ name = string })` | Saída do módulo `network` |
| `volumes_map` | `map({ name, pool })` | Saída do módulo `volume` |
| `cloudinit_volumes_map` | `map({ name, pool })` | Saída do módulo `cloudinit` |

> ⚠️ **Requisito crítico**:  
> As chaves em `volumes_map` devem seguir o padrão `<vm_name>-<disk_name>`.  
> As redes referenciadas em `vms[*].networks[].name` devem existir em `networks_map`.

## Configuração de hardware

- **Firmware**: EFI por padrão, mas o VyOS deve usar `bios`
- **TPM**: habilitado (`tpm-crb`, versão 2.0)
- **CPU**: `host-passthrough`
- **Relógio**: UTC, com timers otimizados
- **Vídeo**: `virtio` (padrão), configurável via `video_model`
- **Canais**: SPICE + QEMU Guest Agent (se `running = true`)
- **Discos**: todos os volumes listados em `disks`, com `bootable = true` marcado com `order = 1`
- **Cloud-init**: anexado como CD-ROM SATA (`sda`) **apenas se existir em `cloudinit_volumes_map`**

## Exemplo de uso

```hcl
locals {
  linux_vyos_vms = {
    for name, vm in var.vms : name => vm
    if vm.os_type == "linux" || vm.os_type == "vyos"
  }
}

module "domain_linux" {
  source                = "../domain_linux"
  vms                   = local.linux_vyos_vms
  networks_map          = module.network.networks
  volumes_map           = module.volume.volumes
  cloudinit_volumes_map = module.cloudinit.cloudinit_volumes
  storage_pool          = var.storage_pool
}
```

## Saídas

- `domains`: mapa indexado pelo nome da VM, contendo:
  - `id`: UUID do domínio no Libvirt
  - `name`: nome da VM

## Limitações conhecidas

- Não suporta múltiplos discos bootáveis (apenas o primeiro com `bootable = true` tem `order = 1`)
- Assume arquitetura `x86_64` e máquina `q35`
- Não permite customização fina de dispositivos além do exposto (ex: serial, USB)
- Requer que todos os templates de Cloud-init estejam presentes e funcionais
