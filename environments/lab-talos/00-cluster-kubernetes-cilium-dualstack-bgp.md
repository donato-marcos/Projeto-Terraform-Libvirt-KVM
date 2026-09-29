
# Laboratório Kubernetes com Cilium e GatewayAPI

Este repositório documenta a implementação de um cluster Kubernetes robusto, utilizando **Cilium** como CNI (substituindo kube-proxy), **Gateway API** para gerenciamento de tráfego e uma stack completa de monitoramento com **Prometheus** e **Hubble**.

O ambiente simula uma topologia de produção com segregação de redes (WAN, Cluster, Storage) rodando sobre virtualização local.

## Ambiente de Hospedagem (Host)

*   **Sistema Operacional:** Fedora 43 (Workstation)
*   **Hypervisor:** KVM/QEMU
*   **Gerenciador:** Libvirt + Virt-Manager
*   **Provisionamento:** Terraform (via projeto modular externo)


## Especificações e Topologia de Rede

> **Nota de Rede:** A subrede IPv4 `192.168.0.240/29` e a subrede IPv6 `2804:14d:3280:4043::eeee:0/124`será reservada para o **Cilium LoadBalancer**, atuando como VIP único para serviços externos.

## Provisionamento com Terraform (Opcional)

Se estiver usando `Libvirt+KVM`, pode usar o **[Projeto-Terraform-Libvirt-KVM](https://github.com/donato-marcos/Projeto-Terraform-Libvirt-KVM)** para automatizar a criação da infra.

### 1. Definição das Redes (`networks.auto.tfvars`)

```json
# networks.auto.tfvars:
networks = [
  {
    name      = "k8s-mgmt"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "172.16.1.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
    ipv6_address      = "fd00:172:16:1::1"
    ipv6_prefix       = 64
    ipv6_dhcp_enabled = false
  },
  {
    name      = "k8s-cluster"
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
    name      = "k8s-storage"
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

Note a ordem das redes definidas, que resulta nas interfaces `enp1s0`, `enp2s0` e `enp3s0` dentro das VMs.

> AJUSTE O ENDEREÇAMENTO IP NA INTERFACE `enp1s0` QUE VAI USAR A BRIDGE

```json
# vm.auto.tfvars:
vms = {
  # BGP Router (VyOS)
  "k8s-vyos" = {
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
        wait_for_lease = true
      },
      {
        name           = "k8s-mgmt"
        ipv4_address   = "172.16.1.254"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:1::254"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-cluster"
        ipv4_address   = "172.16.200.254"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::254"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "172.16.201.254"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::254"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes control-plane
  "k8s-master01" = {
    os_type     = "linux"
    vcpus       = 2
    memory      = 2560
    firmware    = "efi"
    video_model = "virtio"
    graphics    = "spice"
    running     = true
    disks = [
      {
        name     = "os"
        size_gb  = 25
        bootable = true

        backing_store = {
          image  = "ubuntu-24-cloud.x86_64.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "k8s-mgmt"
        ipv4_address   = "172.16.1.11"
        ipv4_prefix    = 24
        ipv4_gateway   = "172.16.1.254"
        ipv6_address   = "fd00:172:16:1::11"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "k8s-cluster"
        ipv4_address   = "172.16.200.11"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::11"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "172.16.201.11"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::11"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes worker
  "k8s-worker01" = {
    os_type     = "linux"
    vcpus       = 2
    memory      = 3072
    firmware    = "efi"
    video_model = "virtio"
    graphics    = "spice"
    running     = true
    disks = [
      {
        name     = "os"
        size_gb  = 25
        bootable = true

        backing_store = {
          image  = "ubuntu-24-cloud.x86_64.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "k8s-mgmt"
        ipv4_address   = "172.16.1.21"
        ipv4_prefix    = 24
        ipv4_gateway   = "172.16.1.254"
        ipv6_address   = "fd00:172:16:1::21"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "k8s-cluster"
        ipv4_address   = "172.16.200.21"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::21"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "172.16.201.21"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::21"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  },

  # Servidor kubernetes worker
  "k8s-worker02" = {
    os_type     = "linux"
    vcpus       = 2
    memory      = 3072
    firmware    = "efi"
    video_model = "virtio"
    graphics    = "spice"
    running     = true
    disks = [
      {
        name     = "os"
        size_gb  = 25
        bootable = true

        backing_store = {
          image  = "ubuntu-24-cloud.x86_64.qcow2"
          format = "qcow2"
        }
      }
    ]
    networks = [
      {
        name           = "k8s-mgmt"
        ipv4_address   = "172.16.1.22"
        ipv4_prefix    = 24
        ipv4_gateway   = "172.16.1.254"
        ipv6_address   = "fd00:172:16:1::22"
        ipv6_prefix    = 64
        ipv6_gateway   = "fd00:172:16:1::254"
        dns_servers    = ["1.1.1.1", "2606:4700:4700::1111"]
        wait_for_lease = false
      },
      {
        name           = "k8s-cluster"
        ipv4_address   = "172.16.200.22"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:200::22"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv4_address   = "172.16.201.22"
        ipv4_prefix    = 24
        ipv6_address   = "fd00:172:16:201::22"
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

ssh_pwauth: true

hostname: ${lower(hostname)}
fqdn: ${lower(hostname)}.teste.local

manage_etc_hosts: true


#chpasswd:
#  list: |
#    root:$6$icCsrgPFmUJ7y40/$2TligMlpR5P2FiFsjrxNZmmYsBmOkpd0sJ4Am/8x6Ko8grcjVf08ZKeUPgiGaNohkZSJrtqVCLKBxGZ6vDY4e1
#  expire: false


users:
  - name: ansible
    gecos: "Usuário de Laboratório"
    groups: [wheel, sudo, admin]
    shell: /bin/bash
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    lock_passwd: false
    passwd: "$6$hTsm9OSnl0JnaIL/$h.UQHqWJaUkU9TEDrZ13xfkampt5imBmM7eap60MIW79cgE.qXj/JDv20RtbDM1iDFoR7UW8VWDJ1xIGQ9LMh."
    ssh_authorized_keys:
      - ${ssh_public.type} ${ssh_public.key} ${ssh_public.host_origin}

package_update: true
package_upgrade: true

timezone: America/Sao_Paulo
locale: en_US.UTF-8
keyboard:
  layout: br
  model: pc105
  variant: abnt2

packages:
  - vim
  - curl
  - wget
  - net-tools
  - git
  - tmux
  - qemu-guest-agent
  - bash-completion
  - python3


runcmd:
  - [ systemctl, enable, --now, qemu-guest-agent.service ]
  - [ timedatectl, set-timezone, America/Sao_Paulo ]
  - |
    #!/bin/bash
    if [ -f /etc/redhat-release ]; then
      localectl set-locale LANG=en_US.UTF-8
      localectl set-keymap br-abnt2
    fi
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
set protocols bgp address-family ipv4-unicast maximum-paths ebgp '4'
set protocols bgp address-family ipv6-unicast maximum-paths ebgp '4'
set protocols bgp neighbor 172.16.200.11 address-family ipv4-unicast
set protocols bgp neighbor 172.16.200.11 remote-as '64513'
set protocols bgp neighbor 172.16.200.21 address-family ipv4-unicast
set protocols bgp neighbor 172.16.200.21 remote-as '64513'
set protocols bgp neighbor 172.16.200.22 address-family ipv4-unicast
set protocols bgp neighbor 172.16.200.22 remote-as '64513'
set protocols bgp neighbor 172.16.200.23 address-family ipv4-unicast
set protocols bgp neighbor 172.16.200.23 remote-as '64513'
set protocols bgp neighbor fd00:172:16:200::11 address-family ipv6-unicast
set protocols bgp neighbor fd00:172:16:200::11 remote-as '64513'
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

Execute em **todos os nós** (`master` e `workers`).

### 1. Configuração Inicial do SO

```bash
# 1. Definir Hostname
sudo hostnamectl hostname k8s-master01    # Para o control-plane
sudo hostnamectl hostname k8s-worker01    # Para o worker 1
sudo hostnamectl hostname k8s-worker02    # Para o worker 2
```


```bash
# 2. Desativar Swap
sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a

# 3. Módulos do Kernel
sudo tee /etc/modules-load.d/containerd.conf > /dev/null << 'EOF'
br_netfilter
cls_bpf
ip_tables
ip6_tables
nf_conntrack
overlay
sch_ingress
sch_fq
xt_CT
xt_mark
xt_socket
xt_TPROXY
EOF
sudo systemctl restart systemd-modules-load.service > /dev/null

# 4. Sysctl para Rede
sudo tee /etc/sysctl.d/99-kubernetes-ipv6.conf > /dev/null << 'EOF'
# Configurando bridges
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1

# Garante que interfaces de Pods herdem as configs de forwarding/IPv6
net.core.devconf_inherit_init_net = 1

# Aumenta o limite de rastreamento de conexões (Conntrack)
net.netfilter.nf_conntrack_max = 1048576

# Encaminhamento necessário para o CNI e K8s
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1
net.ipv4.conf.enp1s0.forwarding = 1
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
net.ipv6.conf.enp1s0.forwarding = 1

# Garante IPv6 ativo nas interfaces
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.enp1s0.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0

# Aceita RA para manter o Default Gateway da VM mesmo como Router (fowarding=1)
net.ipv6.conf.enp1s0.accept_ra = 2

# Aceita NDP
net.ipv6.conf.all.proxy_ndp = 1
net.ipv6.conf.default.proxy_ndp = 1
net.ipv6.conf.enp1s0.proxy_ndp = 1

# Reserva de portas para o cluster kubernetes
net.ipv4.ip_local_reserved_ports = 30000-32767

# Para compatibilidade
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.enp1s0.rp_filter = 0
EOF
sudo sysctl --system
```

### 2. Instalação e Configuração do Containerd

```bash
sudo apt-get install -y containerd
sudo systemctl enable --now containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/\(^\s*SystemdCgroup\s*=\s*\).*/\1true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo grep --color "SystemdCgroup" /etc/containerd/config.toml
```

### 3. Instalação do Kubernetes (v1.36)

```bash
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet
```

### 4. Configurações extras para facilitar, como bash-completion e crictl

```bash
# 1. Configurar o crictl
sudo apt-get install -y cri-tools
sudo tee /etc/crictl.yaml > /dev/null << 'EOF'
runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
timeout: 10
debug: true
EOF

# 2. bash-completion
sudo apt-get install -y bash-completion
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
kubeadm completion bash | sudo tee /etc/bash_completion.d/kubeadm > /dev/null
kubelet completion bash | sudo tee /etc/bash_completion.d/kubelet > /dev/null
crictl completion bash | sudo tee /etc/bash_completion.d/crictl > /dev/null
sudo chmod a+r /etc/bash_completion.d/*
source ~/.bashrc

# 3. Alias
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
```

## Inicialização do Cluster

### 1. Control-Plane (`k8s-master01`)

Crie `kubeadm-config.yaml`:
```yaml
cat > kubeadm-config.yaml << 'EOF'
# kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration

localAPIEndpoint:
  advertiseAddress: "172.16.200.11"
  bindPort: 6443

nodeRegistration:
  criSocket: "unix:///run/containerd/containerd.sock"
  kubeletExtraArgs:
    - name: "node-ip"
      value: "172.16.200.11,fd00:172:16:200::11"

skipPhases:
  - addon/kube-proxy

---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration

clusterName: kubernetes
kubernetesVersion: "v1.36.0"
certificatesDir: /etc/kubernetes/pki
controlPlaneEndpoint: "172.16.200.11:6443"

networking:
  podSubnet: "10.244.0.0/16,fd00:10:244::/56"
  serviceSubnet: "10.96.0.0/12,fd00:10:96::/112"
  dnsDomain: "cluster.local"

apiServer:
  certSANs:
    - "172.16.200.11"
    - "fd00:172:16:200::11"
    - "172.16.1.11"
    - "fd00:172:16:1::11"
    - "kubernetes"
    - "kubernetes.default"
    - "kubernetes.default.svc"
    - "kubernetes.default.svc.cluster.local"
EOF
```

> Optional: You can also perform this action beforehand using 'kubeadm config images pull'

Inicialize:
```bash
sudo kubeadm init --config kubeadm-config.yaml
```
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 2. Worker Nodes

**No Master, gere o comando de join:**  
```bash
kubeadm token create --print-join-command
```
Execute o comando gerado nos workers. Alternativamente, use um arquivo join-config.yaml (lembrando de ajustar o node-ip para cada worker):

```yaml
cat > join-cluster.yaml << 'EOF'
# join-cluster.yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: JoinConfiguration

discovery:
  bootstrapToken:
    apiServerEndpoint: "172.16.200.11:6443"
    token: "<TOKEN>"
    caCertHashes:
      - "sha256:<HASH>"

nodeRegistration:
  criSocket: "unix:///run/containerd/containerd.sock"
  kubeletExtraArgs:
    - name: "node-ip"
      value: "172.16.200.21,fd00:172:16:200::21"
EOF
```

## CNI Cilium, Gateway API e Load Balancing

> **Atenção à Interface:** Com base no ambiente pensado, a interface WAN é **`enp1s0`**. Esta será usada para o L2 Announcement.

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
#kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
```

### 2. Deploy do Cilium (Via Helm + Values)

Configurado para usar `enp1s0` como dispositivo principal para anúncios externos e `enp2s0` para roteamento nativo interno (se necessário ajustar, o Cilium detecta rotas, mas o `devices` deve apontar para a interface física de uplink geral ou específica para BPF).

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

Crie o arquivo `cilium-values.yaml`:
```yaml
cat > cilium-values.yaml << 'EOF'
autoDirectNodeRoutes: true
bgpControlPlane:
  enabled: true
bpf:
  hostLegacyRouting: false
  masquerade: true
  tproxy: false
  datapathMode: auto
cluster:
  id: 1
  name: k8s-cluster
directRoutingSkipUnreachable: false
enableIPv4BIGTCP: true
enableIPv4Masquerade: true
enableIPv6BIGTCP: true
enableIPv6Masquerade: true
#endpointRoutes:
#  enabled: true
envoy:
  enabled: true
  securityContext:
    capabilities:
      envoy:
      - NET_ADMIN
      - SYS_ADMIN
      keepCapNetBindService: true
extraConfig:
  enable-ipv6-ndp: "true"
  ipv6-mcast-device: enp2s0
gatewayAPI:
  enabled: true
hubble:
  enabled: true
  metrics:
    enableOpenMetrics: true
    enabled:
    - dns
    - drop
    - tcp
    - flow
    - port-distribution
    - icmp
    - http
  peerService:
    clusterDomain: cluster.local
  relay:
    enabled: true
  tls:
    enabled: false
  ui:
    enabled: true
ipam:
  mode: kubernetes
  operator:
    clusterPoolIPv4MaskSize: 24
    clusterPoolIPv4PodCIDRList:
    - 10.244.0.0/16
    clusterPoolIPv6MaskSize: 64
    clusterPoolIPv6PodCIDRList:
    - fd00:10:244::/56
ipv4:
  enabled: true
ipv4NativeRoutingCIDR: 10.244.0.0/16
ipv6:
  enabled: true
ipv6NativeRoutingCIDR: fd00:10:244::/56
k8sServiceHost: 172.16.200.11
k8sServicePort: 6443
kubeProxyReplacement: true
loadBalancer:
  acceleration: best-effort
  algorithm: maglev
  dsrDispatch: opt
  l7:
    backend: envoy
    ports: []
  mode: dsr
  serviceTopology: true
  standalone: false
nodePort:
  addresses:
    - 172.16.200.0/24
    - fd00:172:16:200::/64
operator:
  prometheus:
    enabled: true
prometheus:
  enabled: false
routingMode: native
securityContext:
  capabilities:
    ciliumAgent:
    - CHOWN
    - KILL
    - NET_ADMIN
    - NET_RAW
    - NET_BIND_SERVICE
    - IPC_LOCK
    - SYS_MODULE
    - SYS_ADMIN
    - SYS_RESOURCE
    - DAC_OVERRIDE
    - FOWNER
    - SETGID
    - SETUID
    - SYSLOG
    cleanCiliumState:
    - NET_ADMIN
    - SYS_MODULE
    - SYS_ADMIN
    - SYS_RESOURCE
EOF
```

Instale o CNI Cilium:
```bash
helm install cilium oci://quay.io/cilium/charts/cilium \
--version 1.19.4 \
--namespace kube-system \
-f cilium-values.yaml
```

Aguarde a instalação:
```bash
cilium status --wait
```

> **PODE DEMORAR BASTANTE**

# Longhorn

```bash
sudo apt-get install -y nfs-common cryptsetup dmsetup open-iscsi
sudo systemctl enable --now iscsid.service
```

```bash
sudo tee /etc/modules-load.d/longhorn.conf > /dev/null << 'EOF'
nfs
#iscsi_tcp
dm_crypt
vfio_pci
uio_pci_generic
nvme_tcp
ublk_drv
EOF
sudo systemctl restart systemd-modules-load.service > /dev/null
sudo systemctl disable --now multipathd
```

> NOTA: Ative o multipath somente se for usar.

```bash
sudo tee /etc/sysctl.d/99-longhorn-spdk.conf <<EOF
vm.nr_hugepages=1024
EOF
sudo sysctl --system
```
> NOTA: Não é necessário se não for usar SPDK
```bash
curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v1.12.0/longhornctl-linux-amd64
chmod +x longhornctl
export KUBECONFIG=/home/ansible/.kube/config
sudo mv longhornctl /usr/local/bin/
```


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

---

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
-f argocd-values.yaml
```

### Verificar instalação
```bash
kubectl wait --for=condition=Available deployment -n argocd --all --timeout=300s
kubectl get pods -n argocd
```

---

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

## 4. Acesso Inicial e Configuração de Senha

### Recuperar senha inicial do admin
```bash
ADMIN_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
echo "🔑 Senha inicial: $ADMIN_PASS"
```

### Login via CLI
```bash
ARGO_IP=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.spec.clusterIP}')
argocd login "$ARGO_IP" --username admin --password "$ADMIN_PASS" --insecure
```

### Alterar senha (obrigatório)
```bash
# ⚠️ Substitua 'alunofatec' por uma senha forte em produção!
argocd account update-password \
  --current-password "$ADMIN_PASS" \
  --new-password "alunofatec"
```

## 5. Bootstrap GitOps (Integração com k8s-configs)

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

---

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

---

## ⚠️ Solução de Problemas Comuns

| Sintoma | Causa Provável | Solução |
|---------|---------------|---------|
| `HTTPRoute` não funciona | Gateway `public-gateway-ipv4` não existe | `kubectl get gateway -A` e instale o Gateway API |
| Login falha com `--insecure` | ArgoCD está com TLS forçado | Verifique `server.insecure` no values.yaml |
| Apps em `Progressing` infinito | Secret da Cloudflare não aplicado | Veja seção "Configuração Inicial" do [k8s-configs README](https://github.com/donato-marcos/k8s-configs) |
| `kustomize.buildOptions` ignorado | ArgoCD versão antiga | Atualize para v2.9+ ou use initContainer com kustomize |
| Certificado não emite | Solver dns01 sem token válido | Valide secret `cloudflare-api-token` no namespace `cert-manager` |

---

> 🎯 **Status**: ✅ Operacional  
> 🔗 **Próximo passo**: Configure seus apps em [k8s-configs/apps](https://github.com/donato-marcos/k8s-configs/tree/main/apps)  
> 🔐 **Lembrete**: Secrets da Cloudflare devem ser aplicados manualmente antes do bootstrap (ver README principal)

*Documentação alinhada com o repositório k8s-configs

