
# Módulo `domain_windows`

Cria máquinas virtuais Windows no Libvirt/KVM com configuração otimizada para desempenho e compatibilidade.

## Responsabilidade

Este módulo:
- Cria domínios KVM com otimizações específicas do **Hyper-V enlightenments**
- Anexa automaticamente o ISO de drivers VirtIO (`virtio-win-0.1.285.iso`) como CD-ROM SATA
- Configura relógio em `localtime` (recomendado para Windows)
- Ativa TPM 2.0 (requerido para Windows 11, útil para Server 2022+)
- Usa vídeo `qxl` por padrão para melhor integração com SPICE

## O que este módulo **não faz**
- Usar Cloud-init (Windows não é compatível)
- Validar existência do ISO `virtio-win-0.1.285.iso`
- Criar o storage pool `iso` — ele deve existir previamente
- Instalar drivers automaticamente — o ISO é apenas disponibilizado

## Entrada esperada

| Variável | Tipo | Observação |
|--------|------|-----------|
| `vms` | `map(object)` | Apenas VMs com `os_type = "windows"` |
| `networks_map` | `map({ name = string })` | Saída do módulo `network` |
| `volumes_map` | `map({ name, pool })` | Saída do módulo `volume` |

> ⚠️ **Requisito crítico**:  
> - Um **storage pool chamado `iso`** deve existir no Libvirt  
> - Esse pool deve conter o arquivo **`virtio-win-0.1.285.iso`**  
> Caso contrário, o plano falhará com erro de volume inexistente.

## Configuração de hardware

- **Firmware**: EFI por padrão
- **CPU**: `host-passthrough` + *Hyper-V enlightenments* completos
- **Relógio**: `localtime` com timer `hypervclock` habilitado
- **Vídeo**: `qxl` com RAM/VGA configurados para desempenho gráfico
- **Discos**: todos os volumes listados em `disks`, com `bootable = true` marcado com `order = 1`
- **Drivers**: ISO `virtio-win-0.1.285.iso` montado como CD-ROM SATA (`sda`)
- **TPM**: sempre habilitado (`tpm-crb`, versão 2.0)

## Exemplo de uso

```hcl
locals {
  windows_vms = {
    for name, vm in var.vms : name => vm
    if vm.os_type == "windows"
  }
}

module "domain_win" {
  source       = "../domain_win"
  vms          = local.windows_vms
  networks_map = module.network.networks
  volumes_map  = module.volume.volumes
  storage_pool = var.storage_pool
}
```

## Saídas

- `domains`: mapa indexado pelo nome da VM, contendo:
  - `id`: UUID do domínio no Libvirt
  - `name`: nome da VM

## Limitações conhecidas

- ISO de drivers é **hardcoded** como `virtio-win-0.1.285.iso` — não é possível substituir sem modificar o módulo
- Não suporta personalização fina de dispositivos além do exposto
- Assume arquitetura `x86_64` e máquina `q35`
- Requer imagem base Windows pré-configurada
- Não permite múltiplos discos bootáveis (apenas o primeiro com `bootable = true` tem `order = 1`)
