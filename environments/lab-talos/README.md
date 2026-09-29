
# Ambiente `lab`

Ponto de entrada do Terraform para provisionamento de infraestrutura de laboratório com Libvirt/KVM.

## Responsabilidade

Este ambiente:
- Configura o provider Libvirt com URI personalizável (`qemu:///system` por padrão)
- Carrega variáveis de infraestrutura e segredos via arquivos `.auto.tfvars`
- Invoca o módulo `orchestration` para criar toda a infraestrutura
- Não cria recursos diretamente — delega tudo ao orquestrador

## Estrutura de arquivos esperada

Após clonar o repositório, crie os seguintes arquivos a partir dos modelos:

```bash
cd environments/lab
cp vm.auto.tfvars.exemplo vm.auto.tfvars
cp networks.auto.tfvars.exemplo networks.auto.tfvars
cp secrets.auto.tfvars.exemplo secrets.auto.tfvars
```

### Arquivos obrigatórios

| Arquivo | Propósito |
|--------|----------|
| `secrets.auto.tfvars` | Chave SSH pública, URI do Libvirt, storage pool e caminho das imagens base |
| `networks.auto.tfvars` | Definição de redes (NAT, isoladas, IPv4/IPv6, DHCP) |
| `vm.auto.tfvars` | Especificação completa de cada VM (Linux, Windows, VyOS) |

> ⚠️ **Requisito crítico**:  
> - O `storage_pool` e `image_directory` devem apontar para o **mesmo diretório físico**  
> - O storage pool `iso` deve existir com `virtio-win-0.1.285.iso` (para VMs Windows)

## Fluxo de execução

```bash
cd environments/lab
terraform init
terraform validate
terraform apply
```

O plano criará:
- Redes virtuais
- Volumes de disco (com ou sem backing store)
- ISOs de Cloud-init (apenas para Linux/VyOS)
- Domínios KVM (com configurações específicas por sistema operacional)

## Saídas úteis

A saída `provisioned_vms` fornece uma visão consolidada da infraestrutura criada, ideal para geração de inventário Ansible:

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

- Não valida existência de imagens base antes da aplicação
- Não verifica redes já existentes
- Não verifica se redes referenciadas nas VMs foram definidas em `networks.auto.tfvars`
- Requer que todos os templates de Cloud-init estejam presentes nos diretórios corretos
- Versão do provider Libvirt fixada em `= 0.9.1` (não compatível com versões mais antigas sem ajuste)

## Exemplo de uso típico

Este ambiente foi projetado para:
- Laboratórios de estudo (redes, segurança, automação)
- Simulação de topologias com firewall, servidores, estações
- Ambientes heterogêneos (Linux, Windows, VyOS)
- Testes de dual-stack IPv4/IPv6

Suporta:
- Discos com backing store (imagens base qcow2)
- Redes isoladas e NAT
- Cloud-init para Linux/VyOS
- Drivers VirtIO para Windows via CD-ROM