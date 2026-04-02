
# Projeto Terraform Libvirt – Infraestrutura de Laboratório

Este projeto provisiona infraestrutura virtualizada completa com **Terraform + Libvirt/KVM**, voltada para **ambientes de laboratório heterogêneos** com Linux, Windows e VyOS, redes IPv4/IPv6.

## 🎯 Objetivo

Permitir a criação **declarativa e reprodutível** de topologias complexas — incluindo firewalls, servidores, estações, redes isoladas/NAT — com suporte a:
- Cloud-init para Linux/VyOS (chave SSH, rede estática, hostname)
- Drivers VirtIO para Windows via ISO embutido
- Discos com backing store (imagens base qcow2)
- Dual-stack IPv4/IPv6

## 🏗 Arquitetura

O projeto é **modular** e **orientado a environments**:

```
projeto_terraform-libvirt/
├── modules/               # Módulos reutilizáveis
│   ├── orchestration      # Orquestrador central
│   ├── network            # Redes Libvirt (IPv4/IPv6, DHCP, NAT)
│   ├── volume             # Volumes de disco (qcow2/raw, backing store)
│   ├── cloudinit          # ISOs de Cloud-init (Linux/VyOS)
│   ├── domain_linux       # Domínios KVM para Linux/VyOS (EFI, TPM, SMM)
│   └── domain_windows     # Domínios KVM para Windows (Hyper-V, localtime, QXL)
│
└── environments/
    └── lab/               # Ambiente de exemplo (laboratório)
        ├── *.auto.tfvars.exemplo  # Modelos de configuração
        └── README.md      # Instruções específicas do ambiente
```

### Fluxo de execução (orquestração)

1. **Redes** → `module.network`
2. **Volumes** → `module.volume` (todos os discos de todas as VMs)
3. **Cloud-init** → `module.cloudinit` (**apenas** se `os_type = ["linux", "vyos"]`)
4. **Domínios Linux/VyOS** → `module.domain_linux` (com EFI, TPM, Cloud-init)
5. **Domínios Windows** → `module.domain_win` (com Hyper-V, drivers VirtIO, relógio em `localtime`)

> Cada etapa usa `depends_on` para garantir ordem, mesmo sem referências diretas.

## 🚀 Como usar

### Pré-requisitos

- **Libvirt/KVM** instalado e rodando (`libvirtd`)
- **Storage pool `default`** apontando para um diretório com imagens base (ex: `/home/mdonato/vm`)
- **Storage pool `iso`** contendo:
  - `virtio-win-0.1.285.iso` (obrigatório para Windows)
- **Imagens base** no `image_directory` (ex: Ubuntu Cloud, Rocky, Win2022 custom)
- **Templates de Cloud-init** em `modules/cloudinit/templates/{linux,vyos}`

### Passo a passo

1. Clone o repositório  
2. Acesse o ambiente:
   ```bash
   cd environments/lab
   ```
3. Copie os modelos:
   ```bash
   cp *.auto.tfvars.exemplo .
   mv vm.auto.tfvars.exemplo vm.auto.tfvars
   mv networks.auto.tfvars.exemplo networks.auto.tfvars
   mv secrets.auto.tfvars.exemplo secrets.auto.tfvars
   ```
4. Edite os arquivos:
   - `secrets.auto.tfvars`: sua chave SSH, URI, pools
   - `networks.auto.tfvars`: defina suas redes
   - `vm.auto.tfvars`: declare suas VMs
5. Execute:
   ```bash
   terraform init
   terraform validate
   terraform apply
   ```

### Saídas úteis

Após o `apply`, a saída `provisioned_vms` fornece uma estrutura pronta para gerar inventário Ansible:

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

## ⚠️ Limitações e decisões de design

| Aspecto | Detalhe |
|--------|--------|
| **Chave SSH** | Única e global (não por VM) |
| **Windows** | Não usa Cloud-init; drivers via CD-ROM fixo (`virtio-win-0.1.285.iso`) |
| **Validação** | Nenhuma validação prévia de existência de imagens ou redes |
| **Provider** | Versão **fixada em `= 0.9.1`** do `dmacvicar/libvirt` |
| **Escalabilidade** | Projetado para laboratórios; não para produção |

## 📂 Estrutura de arquivos esperada no host

```
/home/mdonato/vm/                # image_directory = storage_pool "default"
├── ubuntu-24-cloud.x86_64.qcow2
├── Rocky-10-GenericCloud-Base.latest.x86_64.qcow2
├── win2k22gui-custom-image.qcow2
└── vyos-custom-image.qcow2

/home/mdonato/Downloads/iso        # ou outro caminho, desde que consistente
└── virtio-win-0.1.285.iso       # dentro do pool "iso"
```

## 📚 Documentação dos módulos

Cada módulo contém seu próprio `README.md` com:
- Responsabilidades exatas
- Entradas/saídas reais
- Limitações técnicas
- Exemplos de uso

Veja:
- [`modules/network/README.md`](modules/network/README.md)
- [`modules/volume/README.md`](modules/volume/README.md)
- [`modules/cloudinit/README.md`](modules/cloudinit/README.md)
- [`modules/domain_linux/README.md`](modules/domain_linux/README.md)
- [`modules/domain_windows/README.md`](modules/domain_windows/README.md)
- [`modules/orchestration/README.md`](modules/orchestration/README.md)

## 🧪 Casos de uso típicos

- Laboratório de segurança (firewall VyOS, DMZ, servidores internos)
- Simulação de rede corporativa (AD, DNS, DHCP, estações Windows/Linux)
- Estudo de IPv6 em redes isoladas
- Ambiente de desenvolvimento com múltiplas distribuições

## 🛠 Requisitos técnicos

- Terraform = 1.14.0 ou OpenTofu = 1.11.0
- Provider `dmacvicar/libvirt` **= 0.9.1**
- QEMU/KVM com suporte a TPM 2.0
- SPICE habilitado (para console gráfico)

---

> Este projeto prioriza **clareza**, **reprodutibilidade** e **fidelidade ao código real** — não abstrações genéricas.