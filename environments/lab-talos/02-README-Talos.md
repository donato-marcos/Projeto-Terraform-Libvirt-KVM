# Talos Linux 1.14.0-rc.2 — Lab Kubernetes (Production-Ready + Multi-NIC)

Laboratório para estudo de Talos Linux, Kubernetes, KVM/QEMU/libvirt, Cilium, Gateway API, ArgoCD e Longhorn.  
Baseado na série **Talos 1.14** (pré-release) e enriquecido com padrões do lab anterior (multi-NIC, dual-stack IPv4/IPv6, BGP, DSR, GitOps).

## Objetivo

Construir um cluster Kubernetes de produção simulada com:

- **Talos Linux** v1.14.0-rc.2
- **3 Control Planes** (HA)
- **2 Workers**
- **KVM + QEMU + libvirt**
- **3 redes isoladas**: Mgmt, Cluster, Storage
- **Dual-stack** IPv4/IPv6
- **Cilium** como CNI (kube-proxy replacement, BGP, DSR, Gateway API)
- **KubePrism** (localhost:7445)
- **Layer 2 VIP** para Kubernetes API
- **Longhorn** para storage persistente
- **ArgoCD** para GitOps
- **VyOS** como roteador BGP externo

### Versões

| Componente | Versão |
|------------|--------|
| Talos | v1.14.0-rc.2 |
| Kubernetes | v1.36.x (bundled) |
| Cilium | 1.19.4 |
| Gateway API | v1.6.1 |
| ArgoCD | latest stable |
| Longhorn | v1.12.0 |

> O `talosctl` deve corresponder à versão do Talos OS instalado nos nós.

---
### Redes libvirt (modo `isolated`)
 
| Rede | CIDR IPv4 | CIDR IPv6 | Função |
|------|-----------|-----------|--------|
| `k8s-mgmt` | 172.16.1.0/24 | fd00:172:16:1::/64 | Acesso Talos API, SSH jump, admin |
| `k8s-cluster` | 172.16.200.0/24 | fd00:172:16:200::/64 | K8s API, Cilium datapath, BGP |
| `k8s-storage` | 172.16.201.0/24 | fd00:172:16:201::/64 | Longhorn replication, SPDK |
 

#### VIPs e Serviços

| Recurso | IP | Rede | Descrição |
|---------|-----|------|-----------|
| Kubernetes API | 172.16.200.10 | cluster | Layer 2 VIP (ARP) |
| Cilium LB IPv4 | 192.168.0.240/29 | WAN (via VyOS) | Pool anunciado por BGP |
| Cilium LB IPv6 | 2804:14d:3280:4043::eeee:0/124 | WAN (via VyOS) | Pool anunciado por BGP |
| VyOS | 172.16.1.254 / 172.16.200.254 / 172.16.201.254 | todas | Router BGP |

> **Importante**: O VIP 172.16.200.10 é **apenas** para o Kubernetes API. O `talosctl` acessa os nós diretamente pelos IPs de **mgmt** (172.16.1.x).

## Provisionamento com Terraform (Opcional)

Se estiver usando `Libvirt+KVM`, pode usar o **[Projeto-Terraform-Libvirt-KVM](https://github.com/donato-marcos/Projeto-Terraform-Libvirt-KVM)** para automatizar a criação da infra.

### 1. Definição das Redes (`networks.auto.tfvars`)

```bash
# networks.auto.tfvars:
networks = [
  {
    name      = "talos-mgmt"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "172.16.1.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
    #ipv4_dhcp_start   = "172.16.1.10"
    #ipv4_dhcp_end     = "172.16.1.200"
    #dhcp_reservations = [
    #  {
    #    mac  = "52:54:00:10:00:11"
    #    ip   = "172.16.1.11"
    #    name = "talos-cp01"
    #  },
    #  {
    #    mac  = "52:54:00:10:00:12"
    #    ip   = "172.16.1.12"
    #    name = "talos-cp02"
    #  },
    #  {
    #    mac  = "52:54:00:10:00:13"
    #    ip   = "172.16.1.13"
    #    name = "talos-cp03"
    #  },
    #  {
    #    mac  = "52:54:00:10:00:21"
    #    ip   = "172.16.1.21"
    #    name = "talos-worker01"
    #  },
    #  {
    #    mac  = "52:54:00:10:00:22"
    #    ip   = "172.16.1.22"
    #    name = "talos-worker02"
    #  },
    #  {
    #    mac  = "52:54:00:10:00:23"
    #    ip   = "172.16.1.23"
    #    name = "talos-worker03"
    #  },
    #]
    ipv6_address      = "fd00:172:16:1::1"
    ipv6_prefix       = 64
    ipv6_dhcp_enabled = false
    #ipv6_dhcp_start   = "fd00:172:16:1::10"
    #ipv6_dhcp_end     = "fd00:172:16:1::200"
  },
  {
    name      = "talos-cluster"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "172.16.200.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
    ipv6_address      = "fd00:172:16:200::1"
    ipv6_prefix       = 64
    ipv6_dhcp_enabled = false
  },
  {
    name      = "talos-storage"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "172.16.201.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
    ipv6_address      = "fd00:172:16:201::1"
    ipv6_prefix       = 64
    ipv6_dhcp_enabled = false
  }
]
```

### 2. Definição das VMs (`vm.auto.tfvars`)

Note a ordem das redes definidas, que resulta nas interfaces `eth0`, `eth1` e `eth2` dentro das VMs.

> AJUSTE O ENDEREÇAMENTO IP NA INTERFACE `eth0` QUE VAI USAR A BRIDGE

```bash
# vm.auto.tfvars:
vms = {
  # BGP Router (VyOS)
  "talos-vyos" = {
    os_type        = "vyos"
    vcpus          = 2
    current_memory = 1024
    memory         = 2048
    firmware       = "bios"
    video_model    = "virtio"
    graphics       = "vnc"
    running        = true
    disks = [
      {
        name     = "os"
        size_gb  = 10 # Em GiB
        bootable = true

        backing_store = {
          image  = "vyos-custom-image.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "bridge0"
        ipv4_address   = "192.168.0.20"
        ipv4_prefix    = 24
        ipv4_gateway   = "192.168.0.1"
        wait_for_lease = true
      },
      {
        name           = "talos-mgmt"
        ipv4_address   = "172.16.1.254"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:1::254"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "talos-cluster"
        ipv4_address   = "172.16.200.254"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::254"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "talos-storage"
        ipv4_address   = "172.16.201.254"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::254"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes control-plane
  "talos-cp01" = {
    os_type     = "talos"
    vcpus       = 2
    memory      = 3072
    firmware    = "efi"
    video_model = "virtio"
    graphics    = "spice"
    running     = true
    disks = [
      {
        name     = "os"
        size_gb  = 40
        bootable = true

        backing_store = {
          image  = "talos-114rc2-nocloud-amd64-secureboot.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "talos-mgmt"
        ipv4_address   = "172.16.1.11"
        ipv4_prefix    = 24
        ipv4_gateway   = "172.16.1.254"
        #mac_address    = "52:54:00:10:00:11"
        ipv6_address   = "fd00:172:16:1::11"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "talos-cluster"
        ipv4_address   = "172.16.200.11"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::11"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "talos-storage"
        ipv4_address   = "172.16.201.11"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::11"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes control-plane
  "talos-cp02" = {
    os_type     = "talos"
    vcpus       = 2
    memory      = 3072
    firmware    = "efi"
    video_model = "virtio"
    graphics    = "spice"
    running     = true
    disks = [
      {
        name     = "os"
        size_gb  = 40
        bootable = true

        backing_store = {
          image  = "talos-114rc2-nocloud-amd64-secureboot.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "talos-mgmt"
        ipv4_address   = "172.16.1.12"
        ipv4_prefix    = 24
        ipv4_gateway   = "172.16.1.254"
        #mac_address    = "52:54:00:10:00:12"
        ipv6_address   = "fd00:172:16:1::12"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "talos-cluster"
        ipv4_address   = "172.16.200.12"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::12"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "talos-storage"
        ipv4_address   = "172.16.201.12"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::12"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes control-plane
  "talos-cp03" = {
    os_type     = "talos"
    vcpus       = 2
    memory      = 3072
    firmware    = "efi"
    video_model = "virtio"
    graphics    = "spice"
    running     = true
    disks = [
      {
        name     = "os"
        size_gb  = 40
        bootable = true

        backing_store = {
          image  = "talos-114rc2-nocloud-amd64-secureboot.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "talos-mgmt"
        ipv4_address   = "172.16.1.13"
        ipv4_prefix    = 24
        ipv4_gateway   = "172.16.1.254"
        #mac_address    = "52:54:00:10:00:13"
        ipv6_address   = "fd00:172:16:1::13"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "talos-cluster"
        ipv4_address   = "172.16.200.13"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::13"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "talos-storage"
        ipv4_address   = "172.16.201.13"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::13"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes worker
  "talos-worker01" = {
    os_type     = "talos"
    vcpus       = 2
    memory      = 4096
    firmware    = "efi"
    video_model = "virtio"
    graphics    = "spice"
    running     = true
    disks = [
      {
        name     = "os"
        size_gb  = 60
        bootable = true

        backing_store = {
          image  = "talos-114rc2-nocloud-amd64-secureboot.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "talos-mgmt"
        ipv4_address   = "172.16.1.21"
        ipv4_prefix    = 24
        ipv4_gateway   = "172.16.1.254"
        #mac_address    = "52:54:00:10:00:21"
        ipv6_address   = "fd00:172:16:1::21"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "talos-cluster"
        ipv4_address   = "172.16.200.21"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::21"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "talos-storage"
        ipv4_address   = "172.16.201.21"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::21"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes worker
  "talos-worker02" = {
    os_type     = "talos"
    vcpus       = 2
    memory      = 4096
    firmware    = "efi"
    video_model = "virtio"
    graphics    = "spice"
    running     = true
    disks = [
      {
        name     = "os"
        size_gb  = 60
        bootable = true

        backing_store = {
          image  = "talos-114rc2-nocloud-amd64-secureboot.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "talos-mgmt"
        ipv4_address   = "172.16.1.22"
        ipv4_prefix    = 24
        ipv4_gateway   = "172.16.1.254"
        #mac_address    = "52:54:00:10:00:22"
        ipv6_address   = "fd00:172:16:1::22"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "talos-cluster"
        ipv4_address   = "172.16.200.22"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::22"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "talos-storage"
        ipv4_address   = "172.16.201.22"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::22"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  }

  # Servidor kubernetes worker
  "talos-worker03" = {
    os_type     = "talos"
    vcpus       = 2
    memory      = 4096
    firmware    = "efi"
    video_model = "virtio"
    graphics    = "spice"
    running     = true
    disks = [
      {
        name     = "os"
        size_gb  = 60
        bootable = true

        backing_store = {
          image  = "talos-114rc2-nocloud-amd64-secureboot.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "talos-mgmt"
        ipv4_address   = "172.16.1.23"
        ipv4_prefix    = 24
        ipv4_gateway   = "172.16.1.254"
        #mac_address    = "52:54:00:10:00:23"
        ipv6_address   = "fd00:172:16:1::23"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "talos-cluster"
        ipv4_address   = "172.16.200.23"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::23"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "talos-storage"
        ipv4_address   = "172.16.201.23"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::23"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  }
}
```
## Exemplo para o cloudinit:
### user-data.yaml.tftpl:
```bash
#cloud-config
${talos_machine_config}
```
### meta-data.yaml.tftpl:
```bash
instance-id: ${hostname}
local-hostname: ${hostname}
```
### network-config.yaml.tftpl:
```bash
network:
  version: 2
  ethernets:
%{ for i, net in networks ~}
    enp${i+1}s0:
      dhcp4: ${net.ipv4_address == "dhcp" ? "true" : "false"}
      dhcp6: ${net.ipv6_address == "dhcp" ? "true" : "false"}
%{   if net.ipv6_address == "dhcp" || (i == 0 && net.ipv6_gateway == null) ~}
      accept-ra: true
%{ else ~}
      accept-ra: false
%{   endif ~}
%{   if (net.ipv4_address != null && net.ipv4_address != "dhcp") || (net.ipv6_address != null && net.ipv6_address != "dhcp") ~}
      addresses:
%{     if net.ipv4_address != null && net.ipv4_address != "dhcp" ~}
        - ${net.ipv4_address}/${net.ipv4_prefix}
%{     endif ~}
%{     if net.ipv6_address != null && net.ipv6_address != "dhcp" ~}
        - ${net.ipv6_address}/${net.ipv6_prefix}
%{     endif ~}
%{   endif ~}
%{   if net.ipv4_gateway != null || net.ipv6_gateway != null ~}
      routes:
%{     if net.ipv4_gateway != null ~}
        - to: 0.0.0.0/0
          via: ${net.ipv4_gateway}
          metric: ${100+i}
%{     endif ~}
%{     if net.ipv6_gateway != null ~}
        - to: "::/0"
          via: ${net.ipv6_gateway}
          metric: ${100+i}
%{     endif ~}
%{   endif ~}
%{   if length(net.dns_servers) > 0 ~}
      nameservers:
        addresses: ${jsonencode(net.dns_servers)}
%{   endif ~}
%{ endfor ~}
```
## Pré-requisitos e Configuração dos Nós

Execute no k8s-vyos:

```bash
# --- Configuração de Firewall/NAT ---
  
# Configurar NAT (masquerade) para todas as redes internas
set nat source rule 10 outbound-interface name 'eth0'
set nat source rule 10 translation address 'masquerade'
set nat66 source rule 10 outbound-interface name 'eth0'
set nat66 source rule 10 translation address 'masquerade'

# Configurar BGP
set protocols bgp address-family ipv4-unicast maximum-paths ebgp '4'
set protocols bgp address-family ipv6-unicast maximum-paths ebgp '4'
set protocols bgp neighbor 172.16.200.11 address-family ipv4-unicast
set protocols bgp neighbor 172.16.200.11 remote-as '64513'
set protocols bgp neighbor 172.16.200.12 address-family ipv4-unicast
set protocols bgp neighbor 172.16.200.12 remote-as '64513'
set protocols bgp neighbor 172.16.200.13 address-family ipv4-unicast
set protocols bgp neighbor 172.16.200.13 remote-as '64513'
set protocols bgp neighbor 172.16.200.21 address-family ipv4-unicast
set protocols bgp neighbor 172.16.200.21 remote-as '64513'
set protocols bgp neighbor 172.16.200.22 address-family ipv4-unicast
set protocols bgp neighbor 172.16.200.22 remote-as '64513'
set protocols bgp neighbor 172.16.200.23 address-family ipv4-unicast
set protocols bgp neighbor 172.16.200.23 remote-as '64513'
set protocols bgp neighbor fd00:172:16:200::11 address-family ipv6-unicast
set protocols bgp neighbor fd00:172:16:200::11 remote-as '64513'
set protocols bgp neighbor fd00:172:16:200::12 address-family ipv6-unicast
set protocols bgp neighbor fd00:172:16:200::12 remote-as '64513'
set protocols bgp neighbor fd00:172:16:200::13 address-family ipv6-unicast
set protocols bgp neighbor fd00:172:16:200::13 remote-as '64513'
set protocols bgp neighbor fd00:172:16:200::21 address-family ipv6-unicast
set protocols bgp neighbor fd00:172:16:200::21 remote-as '64513'
set protocols bgp neighbor fd00:172:16:200::22 address-family ipv6-unicast
set protocols bgp neighbor fd00:172:16:200::22 remote-as '64513'
set protocols bgp neighbor fd00:172:16:200::23 address-family ipv6-unicast
set protocols bgp neighbor fd00:172:16:200::23 remote-as '64513'
set protocols bgp parameters bestpath as-path multipath-relax
set protocols bgp system-as '64512'
set service ndp-proxy interface eth0 prefix 2804:14d:3280:4043::eeee:0/124
commit
save
```


## Estrutura de Diretórios

```bash
~/lab-talos/
└──talos/
   ├── configs
   │   ├── patches
   │   │   ├── common
   │   │   │   ├── cni.yaml
   │   │   │   ├── install.yaml
   │   │   │   ├── kubernetes.yaml
   │   │   │   ├── ntp.yaml
   │   │   │   └── sysctl.yaml
   │   │   ├── controlplane
   │   │   │   ├── admissioncontrol.yaml
   │   │   │   ├── kubeproxy.yaml
   │   │   │   └── vip.yaml
   │   │   └── worker
   │   │       └── longhorn-v1.yaml
   │   ├── controlplane.yaml
   │   ├── talosconfig
   │   └── worker.yaml
   └── secrets.yaml
```

## Fase 1: Preparação (Production Notes)

Instalar o cli do talos:
```bash
curl -LO https://github.com/siderolabs/talos/releases/download/v1.14.0/talosctl-linux-amd64
chmod +x talosctl-linux-amd64
sudo mv talosctl-linux-amd64 /usr/local/bin/talosctl
```
bash-completion (opcional, facilita o dia a dia):
```bash
talosctl completion bash | sudo tee /etc/bash_completion.d/talosctl > /dev/null
sudo chmod a+r /etc/bash_completion.d/talosctl
source ~/.bashrc
```
### Variáveis de Ambiente

```bash
export CLUSTER_NAME="k8s-cluster"
export K8S_API_VIP="172.16.200.10"

export CONTROL_PLANE_IP=("172.16.1.11" "172.16.1.12" "172.16.1.13")
export WORKER_IP=("172.16.1.21" "172.16.1.22" "172.16.1.23")
```

### Verificar talosctl

```bash
talosctl version --client
```

### Descobrir Hardware dos Nós

Durante o maintenance mode (ISO boot), verifique em um nó de cada tipo:

```bash
# Interfaces
talosctl -n 172.16.1.11 get links --insecure

# Discos
talosctl -n 172.16.1.11 get disks --insecure
```

> Anote o `dev_path` do disco (ex: `/dev/vda`) e confirme os nomes das interfaces.

## Fase 2: Configuração Talos 1.14

### Abordagem Multi-Documento

A série 1.14 introduz configuração baseada em múltiplos documentos YAML independentes.  
**Não usaremos** o patch legado monolítico (`machine.network.interfaces[0].vip`).

### Gerar Secrets Bundle

```bash
cd ~/lab-talos
talosctl gen secrets -o talos/secrets.yaml
```

> Guarde `secrets.yaml` com segurança. Contém chaves criptográficas sensíveis.

### Gerar Configurações Base

```bash
cd ~/lab-talos/talos/configs

talosctl gen config \
  --with-secrets ../secrets.yaml \
  --talos-version v1.14.0 \
  --config-patch @patches/common/sysctl.yaml \
  --config-patch @patches/common/kubernetes.yaml \
  --config-patch @patches/common/cni.yaml \
  --config-patch @patches/common/ntp.yaml \
  --config-patch @patches/common/install.yaml \
  --config-patch-control-plane @patches/controlplane/kubeproxy.yaml \
  --config-patch-control-plane @patches/controlplane/vip.yaml \
  --config-patch-control-plane @patches/controlplane/admissioncontrol.yaml \
  --config-patch-worker @patches/worker/longhorn-v1.yaml \
  "$CLUSTER_NAME" \
  "https://${K8S_API_VIP}:6443" \
  --output ./
```

## Fase 3: Instalação

### Aplicar Configuração nos Control Planes

```bash
for ip in "${CONTROL_PLANE_IP[@]}"; do
    echo "=== Aplicando em $ip ==="
    talosctl apply-config --insecure \
      --nodes "$ip" \
      --file talos/configs/controlplane.yaml
    echo "Configuração aplicada em $ip"
    echo ""
done
```

### Aplicar Configuração nos Workers

```bash
for ip in "${WORKER_IP[@]}"; do
    echo "=== Aplicando em $ip ==="
    talosctl apply-config --insecure \
      --nodes "$ip" \
      --file talos/configs/worker.yaml
    echo "Configuração aplicada em $ip"
    echo ""
done
```

> O `UnattendedInstallConfig` fará a instalação automática no disco. Os nós reiniciarão e sairão do maintenance mode.

## Fase 4: Bootstrap e Acesso

### Configurar talosctl

```bash
# Opção 1: Merge
talosctl config merge ./talos/configs/talosconfig

## Opção 2: Arquivo separado
#mkdir -p ~/.talos
#cp ./talos/configs/talosconfig ~/.talos/config
#export TALOSCONFIG=~/.talos/config
```

### Endpoints para HA

```bash
talosctl config endpoint "${CONTROL_PLANE_IP[@]}"
```

### Bootstrap do etcd

> **Execute UMA ÚNICA VEZ** em UM único CP.

```bash
export BOOTSTRAP_NODE="${CONTROL_PLANE_IP[0]}"
talosctl bootstrap --nodes "$BOOTSTRAP_NODE"
```

### Obter Kubeconfig

```bash
# Opção 1: Merge
talosctl kubeconfig --merge --nodes "$BOOTSTRAP_NODE"

## Opção 2: Arquivo separado
#talosctl kubeconfig alternative-kubeconfig --nodes "$BOOTSTRAP_NODE"
#export KUBECONFIG=./alternative-kubeconfig
```

### Verificar Nós

```bash
kubectl get nodes -o wide
```

## CNI Cilium, Gateway API e Load Balancing

> **Atenção à Interface:** Com base no ambiente pensado, a interface WAN é **`eth0`**. Esta será usada para o L2 Announcement ou BGP

### 1. Preparação (Helm e CRDs)

```bash
# Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh
helm version

helm completion bash | sudo tee /etc/bash_completion.d/helm > /dev/null
sudo chmod a+r /etc/bash_completion.d/helm
source ~/.bashrc

# Gateway API CRDs
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml

# CRD para Service Monitor
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/refs/heads/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/refs/heads/main/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
#ou
#kubectl apply --server-side -f https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.93.1/bundle.yaml
```

```bash
# Cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium completion bash | sudo tee /etc/bash_completion.d/cilium > /dev/null
sudo chmod a+r /etc/bash_completion.d/cilium
source ~/.bashrc
```

### Instalar Cilium

```bash
helm install cilium oci://quay.io/cilium/charts/cilium \
--version 1.20.1 \
--namespace kube-system \
-f talos/cilium-values.yaml

# Aguardar
cilium status --wait
```

### Validar

```bash
# Sem kube-proxy
kubectl -n kube-system get pods | grep -i proxy
# (deve retornar vazio)

# Cilium OK
kubectl -n kube-system get pods -l k8s-app=cilium

# BGP peering (se VyOS configurado)
kubectl exec -n kube-system ds/cilium -- cilium bgp peers
```

> No Cilium, configure o `CiliumBGPPeeringPolicy` apontando para o VyOS (172.16.200.254 / fd00:172:16:200::254, ASN 64512).

> **A PARTIR DAQUI, você pode querer automatizar utilizando o [ArgoCD](instalar-argocd.md)**

# 🚀 Instalação do Argo CD — Homelab GitOps

Guia para instalação e configuração do **Argo CD** no cluster Kubernetes do laboratório, integrado ao repositório GitOps [k8s-configs](https://github.com/donato-marcos/k8s-configs).

> 🔗 **Relação com o projeto principal**: Este setup é consumido pelo bootstrap definido em `clusters/homelab/bootstrap/root-infra.yaml` do repositório [k8s-configs](https://github.com/donato-marcos/k8s-configs).

---

## 📋 Pré-requisitos

- Cluster Kubernetes funcional (v1.25+)
- `kubectl` configurado e com acesso ao cluster
- `helm` instalado (v3.10+)
- **Gateway API** instalado e configurado (`meu-gateway-dualstack` no namespace `default`)
- DNS configurado apontando `argocd.aesthar.com.br` para o LoadBalancer/Ingress

## 1. Instalar o Argo CD via Helm

### Criar arquivo de valores personalizados
```bash
cat > argocd-values.yaml << 'EOF'
# argocd-values.yaml
---
configs:
  params:
    server.insecure: "true"

  cm:
    kustomize.buildOptions: "--enable-helm"
EOF
```
> 🔐 **Em produção**: Configure TLS via `cert-manager` + `ClusterIssuer` e use `server.insecure: false`.

### Instalar o chart oficial
```bash
helm install argocd oci://ghcr.io/argoproj/argo-helm/argo-cd \
--namespace argocd \
--create-namespace \
-f talos/argocd-values.yaml
```

### Verificar instalação
```bash
kubectl wait --for=condition=Available deployment -n argocd --all --timeout=300s
kubectl get pods -n argocd
```

## 2. Instalar o Argo CD CLI

```bash
# Download e instalação (Linux AMD64)
curl -sSL -o argocd-linux-amd64 \
  https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Verificar instalação
argocd version --client
```

> 💡 **Outras plataformas**: Consulte [argoproj.github.io/argo-cd/cli_installation](https://argo-cd.readthedocs.io/en/stable/cli_installation/)

### Autocomplete no Bash (opcional)
```bash
argocd completion bash | sudo tee /etc/bash_completion.d/argocd > /dev/null
sudo chmod a+r /etc/bash_completion.d/argocd
source ~/.bashrc
```
## 4. Bootstrap GitOps (Integração com k8s-configs)

> 🎯 Esta etapa conecta o Argo CD ao repositório central de configurações: [k8s-configs](https://github.com/donato-marcos/k8s-configs)

### Passo 1: Aplicar root-infra.yaml
Instala componentes de infraestrutura (Cilium, cert-manager, external-dns, etc.):

```bash
kubectl apply -f https://raw.githubusercontent.com/donato-marcos/k8s-configs/refs/heads/main/clusters/homelab/bootstrap/root-infra.yaml
```

### Passo 2: Aguardar estabilização
```bash
# Monitorar sincronização no ArgoCD
watch kubectl get applications -n argocd

# Ou via CLI:
argocd app list -n argocd
```

## 5. Acesso Inicial e Configuração de Senha

### Recuperar senha inicial do admin
```bash
ADMIN_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
echo "🔑 Senha inicial: $ADMIN_PASS"
```

### Login via CLI
```bash
argocd login "argocd.aesthar.com.br:80" --username admin --password "$ADMIN_PASS" --insecure
```

### Alterar senha (obrigatório)
```bash
# ⚠️ Substitua 'alunofatec' por uma senha forte em produção!
argocd account update-password \
  --current-password "$ADMIN_PASS" \
  --new-password "alunofatec"
```

### Passo 3: Aplicar root-infra.yaml
Após a infra estar `Healthy/Synced`, sincronize as aplicações:

```bash
kubectl apply -f https://raw.githubusercontent.com/donato-marcos/k8s-configs/refs/heads/main/clusters/homelab/bootstrap/root-infra.yaml
```

### Verificar resultado final
```bash
# Todas as aplicações devem estar Synced + Healthy
argocd app list -n argocd

# Exemplo de saída esperada:
# NAME                   SYNC STATUS  HEALTH STATUS
# argocd                 Synced       Healthy
# cert-manager           Synced       Healthy
# cilium                 Synced       Healthy
# atv4-compassuol        Synced       Healthy
```

## 🛠️ Comandos Úteis

```bash
# ===== Gerenciamento de Apps =====
argocd app list -n argocd
argocd app get <app-name> -n argocd
argocd app sync <app-name> -n argocd --force
argocd app logs <app-name> -n argocd --follow

# ===== Debug de Sync =====
kubectl describe application <app-name> -n argocd
kubectl get events -n argocd --field-selector involvedObject.name=<app-name>

# ===== Acesso à UI =====
# Port-forward local (alternativa ao Gateway):
kubectl port-forward svc/argocd-server -n argocd 8080:80
# Acesse: http://localhost:8080

# ===== Backup/Restore de Config =====
# Exportar configurações do ArgoCD:
kubectl get secret argocd-initial-admin-secret -n argocd -o yaml > backup-admin-secret.yaml
```

## ⚠️ Solução de Problemas Comuns

| Sintoma | Causa Provável | Solução |
|---------|---------------|---------|
| `HTTPRoute` não funciona | Gateway `public-gateway-ipv4` não existe | `kubectl get gateway -A` e instale o Gateway API |
| Login falha com `--insecure` | ArgoCD está com TLS forçado | Verifique `server.insecure` no values.yaml |
| Apps em `Progressing` infinito | Secret da Cloudflare não aplicado | Veja seção "Configuração Inicial" do [k8s-configs README](https://github.com/donato-marcos/k8s-configs) |
| `kustomize.buildOptions` ignorado | ArgoCD versão antiga | Atualize para v2.9+ ou use initContainer com kustomize |
| Certificado não emite | Solver dns01 sem token válido | Valide secret `cloudflare-api-token` no namespace `cert-manager` |

> 🎯 **Status**: ✅ Operacional  
> 🔗 **Próximo passo**: Configure seus apps em [k8s-configs/apps](https://github.com/donato-marcos/k8s-configs/tree/main/apps)  
> 🔐 **Lembrete**: Secrets da Cloudflare devem ser aplicados manualmente antes do bootstrap (ver README principal)

*Documentação alinhada com o repositório k8s-configs

## Estado Atual do Laboratório

- [x] Arquitetura definida (3 CP, 2 Workers)
- [x] Multi-NIC (Mgmt, Cluster, Storage)
- [x] Dual-stack IPv4/IPv6
- [x] KVM/QEMU + libvirt
- [x] Talos v1.14.0-rc.2
- [x] Cilium (kube-proxy replacement, BGP, DSR, Gateway API)
- [x] KubePrism
- [x] Layer 2 VIP
- [x] Secrets bundle
- [x] UnattendedInstallConfig
- [x] Longhorn (system extensions)
- [x] ArgoCD (GitOps)
- [x] VyOS BGP
- [ ] Confirmar nomes das interfaces no Talos (multi-NIC)
- [ ] Gerar secrets e configs
- [ ] Aplicar patches
- [ ] Instalar nós
- [ ] Bootstrap etcd
- [ ] Instalar Cilium
- [ ] Configurar BGP com VyOS
- [ ] Instalar Longhorn
- [ ] Instalar ArgoCD + bootstrap
- [ ] Testar HA e failover

## Referências

- **Talos Linux — Production Notes**: https://docs.siderolabs.com/talos/v1.14/getting-started/prodnotes
- **Talos Linux — Configuration Overview**: https://docs.siderolabs.com/talos/v1.14/reference/configuration/overview
- **Talos Linux — Paching**: https://docs.siderolabs.com/talos/v1.14/configure-your-talos-cluster/system-configuration/patching
- **Talos Linux — Cilium**: https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium#without-kube-proxy-%2B-gateway-api
- **Talos Image Factory**: https://factory.talos.dev/
- **Cilium Docs**: https://docs.cilium.io/
- **Gateway API**: https://gateway-api.sigs.k8s.io/
- **ArgoCD**: https://argo-cd.readthedocs.io/
- **Longhorn**: https://longhorn.io/docs/
