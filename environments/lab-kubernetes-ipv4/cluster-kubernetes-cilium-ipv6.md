
# Laboratório Kubernetes com Cilium e GatewayAPI

Este repositório documenta a implementação de um cluster Kubernetes robusto, utilizando **Cilium** como CNI (substituindo kube-proxy), **Gateway API** para gerenciamento de tráfego e uma stack completa de monitoramento com **Prometheus** e **Hubble**.

O ambiente simula uma topologia de produção com segregação de redes (WAN, Cluster, Storage) rodando sobre virtualização local.

## Ambiente de Hospedagem (Host)

*   **Sistema Operacional:** Fedora 43 (Workstation)
*   **Hypervisor:** KVM/QEMU
*   **Gerenciador:** Libvirt + Virt-Manager
*   **Provisionamento:** Terraform (via projeto modular externo)

---

## Especificações e Topologia de Rede

O cluster possui 3 nós Ubuntu Server. A identificação correta das interfaces de rede é crucial para a configuração do Cilium.

| Hostname | vCPU | vRAM | Interface WAN (`enp1s0`) | Interface Cluster (`enp2s0`) | Interface Storage (`enp3s0`) |
| :--- | :---: | :---: | :--- | :--- | :--- |
| `k8s-master01` | 2 | 2.5 GB | `2804:14d:3280:46c4::11` | `fd00:172:16:200::11` | `fd00:172:16:201::11` |
| `k8s-worker01` | 2 | 3.0 GB | `2804:14d:3280:46c4::21` | `fd00:172:16:200::21` | `fd00:172:16:201::21` |
| `k8s-worker02` | 2 | 3.0 GB | `2804:14d:3280:46c4::22` | `fd00:172:16:200::22` | `fd00:172:16:201::22` |

> **Nota de Rede:** O IP `2804:14d:3280:46c4::9` será reservado para o **Cilium LoadBalancer**, atuando como VIP único para serviços externos. O anúncio L2 será feito na interface **`enp1s0`**.

---

## Provisionamento com Terraform (Opcional)

Se estiver usando `Libvirt+KVM`, pode usar o **[Projeto-Terraform-Libvirt-KVM](https://github.com/donato-marcos/Projeto-Terraform-Libvirt-KVM)** para automatizar a criação da infra.

### 1. Definição das Redes (`networks.auto.tfvars`)

```hcl
networks = [
  {
    name      = "k8s-cluster"
    mode      = "isolated"
    autostart = true

    ipv6_address      = "fd00:172:16:200::1"
    ipv6_prefix       = 64
    ipv6_dhcp_enabled = false
  },
  {
    name      = "k8s-storage"
    mode      = "isolated"
    autostart = true

    ipv6_address      = "fd00:172:16:201::1"
    ipv6_prefix       = 64
    ipv6_dhcp_enabled = false
  }
]
```

### 2. Definição das VMs (`vm.auto.tfvars`)

Note a ordem das redes definidas, que resulta nas interfaces `enp1s0`, `enp2s0` e `enp3s0` dentro das VMs.

```hcl
# vm.auto.tfvars:
vms = {

  # Servidor kubernetes control-plane
  "k8s-master01" = {
    os_type     = "linux"
    vcpus       = 2
    memory      = 4096
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
        name         = "bridge0"
        ipv6_address = "2804:14d:3280:46c4::11"
        ipv6_prefix  = 64
        wait_for_lease = true
      },
      {
        name           = "k8s-cluster"
        ipv6_address   = "fd00:172:16:200::11"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
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
    memory      = 8192
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
        name         = "bridge0"
        ipv6_address = "2804:14d:3280:46c4::21"
        ipv6_prefix  = 64
        wait_for_lease = true
      },
      {
        name           = "k8s-cluster"
        ipv6_address   = "fd00:172:16:200::21"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
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
    memory      = 8192
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
        name         = "bridge0"
        ipv6_address = "2804:14d:3280:46c4::22"
        ipv6_prefix  = 64
        wait_for_lease = true
      },
      {
        name           = "k8s-cluster"
        ipv6_address   = "fd00:172:16:200::22"
        ipv6_prefix    = 64
        wait_for_lease = false
      },
      {
        name           = "k8s-storage"
        ipv6_address   = "fd00:172:16:201::22"
        ipv6_prefix    = 64
        wait_for_lease = false
      }
    ]
  }
}
```

---

## Pré-requisitos e Configuração dos Nós

Execute em **todos os nós** (`master` e `workers`).

### 1. Configuração Inicial do SO

```bash
# 1. Definir Hostname
sudo hostnamectl hostname kube-master01    # Para o control-plane
sudo hostnamectl hostname kube-worker01    # Para o worker 1
sudo hostnamectl hostname kube-worker02    # Para o worker 2

# 2. Desativar Swap
sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a

# 3. Módulos do Kernel
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# 4. Sysctl para Rede
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
# Habilitar Forwarding (Roteamento)
net.ipv4.conf.all.forwarding = 1
net.ipv6.conf.all.forwarding = 1

# Garantir que IPv6 não esteja desabilitado no kernel
net.ipv6.conf.all.disable_ipv6 = 0

# CRÍTICO: Fazer bridges respeitarem as regras de firewall do K8s
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
```

### 2. Instalação e Configuração do Containerd

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gpg gnupg bash-completion
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y containerd.io
sudo systemctl enable --now containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo grep "SystemdCgroup" /etc/containerd/config.toml
```

### 3. Instalação do Kubernetes (v1.35)

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### 4. Configurações extrar para ficilitar, como bash-completion e crictl

```bash
# 1. Configurar o crictl
cat << EOF | sudo tee /etc/crictl.yaml
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
```

---

## Inicialização do Cluster

### 1. Control-Plane (`k8s-master01`)

Crie `kubeadm-config.yaml`:
```yaml
# kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration

localAPIEndpoint:
  advertiseAddress: "fd00:172:16:200::11"
  bindPort: 6443
  
nodeRegistration:
  criSocket: "unix:///run/containerd/containerd.sock"
  kubeletExtraArgs:
    - name: "node-ip"
      value: "fd00:172:16:200::11"
    
skipPhases:
  - addon/kube-proxy
  
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration

clusterName: kubernetes
kubernetesVersion: v1.35.0
certificatesDir: /etc/kubernetes/pki
controlPlaneEndpoint: "[fd00:172:16:200::11]:6443"

networking:
  serviceSubnet: "fd00:10:96::/112"
  podSubnet: "fd00:10:244::/56"
  dnsDomain: "cluster.aesthar.com.br"

apiServer:
  certSANs:
    - fd00:172:16:200::11
    - 2804:14d:3280:46c4::11
  extraArgs:
    bind-address: "::"
    advertise-address: "fd00:172:16:200::11"

controllerManager:
  extraArgs:
    bind-address: "::"
    allocate-node-cidrs: "true"
    node-cidr-mask-size: "64"

scheduler:
  extraArgs:
    bind-address: "::"

etcd:
  local:
    dataDir: /var/lib/etcd
    extraArgs:
      listen-client-urls: "https://[fd00:172:16:200::11]:2379"
      advertise-client-urls: "https://[fd00:172:16:200::11]:2379"
      listen-peer-urls: "https://[fd00:172:16:200::11]:2380"
      initial-advertise-peer-urls: "https://[fd00:172:16:200::11]:2380"
```

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

```bash
# join-cluster.yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: JoinConfiguration

discovery:
  bootstrapToken:
    apiServerEndpoint: "[fd00:172:16:200::11]:6443"
    token: "<TOKEN_GERADO_NO_MASTER>"
    caCertHashes:
      - "sha256:<HASH>"

nodeRegistration:
  criSocket: "unix:///run/containerd/containerd.sock"
  kubeletExtraArgs:
    - name: "node-ip"
      value: "fd00:172:16:200::21"
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
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml
```

### 2. Deploy do Cilium (Via Helm + Values)

Configurado para usar `enp1s0` como dispositivo principal para anúncios externos e `enp2s0` para roteamento nativo interno (se necessário ajustar, o Cilium detecta rotas, mas o `devices` deve apontar para a interface física de uplink geral ou específica para BPF).

Neste caso, como temos múltiplas interfaces, vamos definir `devices=enp1s0` para garantir que o LoadBalancer funcione na rede WAN, e o Cilium gerenciará o roteamento entre os pods.

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
# cilium-values.yaml
# --- Kubernetes API ---
k8sServiceHost: "fd00:172:16:200::11"
k8sServicePort: 6443

# --- IPv4/IPv6 (Dual-Stack) ---
ipv4:
  enabled: false
enableIPv4Masquerade: false

ipv6:
  enabled: true
enableIPv6Masquerade: true

masqueradeInterfaces: "enp1s0"

# --- kube-proxy replacement ---
# Substitui totalmente o kube-proxy usando eBPF
kubeProxyReplacement: true
#enableHostFirewall: true # pode deixar o lab mais complicado, cuidado.

# --- Datapath & Roteamento Nativo ---
# Inclui ambas as interfaces relevantes: WAN (para LB) e Cluster (para Pods)
devices:
  - enp2s0
  - enp1s0
  
routingMode: native
autoDirectNodeRoutes: true

# Define os CIDRs globais para roteamento nativo (opcional se o IPAM já estiver correto, mas bom para explícito)
ipv6NativeRoutingCIDR: "fd00:10:244::/56"

# --- IPAM (Gerenciamento de IPs) ---
ipam:
  mode: kubernetes
  operator:
    # Pool IPv6: /56 dividido em /64 por nó
    clusterPoolIPv6PodCIDRList: ["fd00:10:244::/56"]
    clusterPoolIPv6MaskSize: 64

cluster:
  name: k8s-cluster
  id: 1

# --- L2 Announcements (Substitui MetalLB) ---
l2announcements:
  enabled: true
  # Anuncia VIPs apenas na interface WAN (enp1s0) para IPv4 e IPv6
  interfaces:
    - "^enp1s0$"

externalIPs:
  enabled: true

loadBalancer:
  mode: snat
  l2:
    enabled: true

nodePort:
  enabled: true

# --- Gateway API (Substitui Ingress-Nginx) ---
gatewayAPI:
  enabled: true

envoy:
  enabled: true

# --- Hubble (Observabilidade) ---
hubble:
  enabled: true
  relay:
    enabled: true
  ui:
    enabled: true
  metrics:
    enabled:
      - dns
      - drop
      - tcp
      - flow
      - port-distribution
      - icmp
      - http

operator:
  prometheus:
    enabled: true
    
# --- Prometheus Integrado (Opcional) ---
# Deixado falso pois você usará a stack kube-prometheus separada
prometheus:
  enabled: false

# --- Segurança (Capabilities) ---
securityContext:
  capabilities:
    ciliumAgent:
      - NET_ADMIN
      - SYS_ADMIN
      - NET_RAW
      - IPC_LOCK
      - SYS_RESOURCE
      - DAC_OVERRIDE
      - FOWNER
      - SETGID
      - SETUID

# --- Performance e BPF ---
bpf:
  masquerade: true
  hostRouting: true
  tproxy: true
```

Instale o CNI Cilium:
```bash
helm repo add cilium https://helm.cilium.io/
helm repo update

helm install cilium cilium/cilium \
--version 1.19.1 \
--namespace kube-system \
-f cilium-values.yaml
```

Aguarde a instalação:
```bash
cilium status --wait
```

> **PODE DEMORAR BASTANTE**

### 3. Configuração do LoadBalancer L2 e Gateway

Crie o arquivo `l2-ipv6-pool.yaml`:

```yaml
#l2-ipv6-pool.yaml
apiVersion: "cilium.io/v2"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "wan-pool-ipv6"
spec:
  blocks:
    - cidr: "2804:14d:3280:46c4::9/128"
---
apiVersion: "cilium.io/v2alpha1"
kind: CiliumL2AnnouncementPolicy
metadata:
  name: "wan-announcement-policy-ipv6"
spec:
  nodeSelector:
    matchLabels:
      kubernetes.io/os: linux
  serviceSelector:
    matchLabels:
      io.kubernetes.service.name: cilium-gateway-my-gateway-ipv6
  interfaces:
    - "^enp1s0$" # Anuncia o IP VIP apenas na interface WAN
  externalIPs: true
  loadBalancerIPs: true
```
E aplique com:
```bash
kubectl apply -f l2-ipv6-pool.yaml
```

Crie o arquivo `gateway-ipv6.yaml`:
```yaml
# gateway-ipv6.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway-ipv6
  namespace: default
  annotations:
    io.cilium/lb-ipam-ips: "2804:14d:3280:46c4::9"
spec:
  gatewayClassName: cilium
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
```

E aplique com:
```bash
kubectl apply -f gateway-ipv6.yaml
```
---

## Monitoramento e Observabilidade

### 1. Metrics Server

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update

helm install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set "args={--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname}"
```
> **O Metrics-server é necessário para o HPA e VPA funcionar**


### 2. Stack Prometheus:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
--namespace monitoring \
--create-namespace \
--set grafana.adminPassword=alunofatec \
--set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
--set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false
```

Crie `monitoring-httproutes.yaml`:

```yaml
# monitoring-httproute.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: hubble-ui-route
  namespace: kube-system
spec:
  parentRefs:
  - name: my-gateway-ipv6
    namespace: default
  hostnames:
  - "hubble.aesthar.com.br"
  rules:
  - backendRefs:
    - name: hubble-ui
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: monitoring-grafana-route
  namespace: monitoring
spec:
  parentRefs:
  - name: my-gateway-ipv6
    namespace: default
  hostnames:
  - "grafana.aesthar.com.br"
  rules:
  - backendRefs:
    - name: monitoring-grafana
      port: 80
```
E aplique com:
```bash
kubectl apply -f monitoring-httproutes.yaml
```


### Acesso Local

No seu host Fedora, edite `/etc/hosts`:
```bash
echo "2804:14d:3280:46c4::9 hubble.aesthar.com.br" | sudo tee -a /etc/hosts
echo "2804:14d:3280:46c4::9 grafana.aesthar.com.br" | sudo tee -a /etc/hosts

```

Acesse:
*   **Hubble:** http://hubble.aesthar.com.br
*   **Grafana:** http://grafana.aesthar.com.br (admin / alunofatec)

---

## Validação Final

```bash
# Verificar se o Cilium está saudável
cilium status

# Verificar se o IP 192.168.200.9 foi atribuído ao Gateway
kubectl get gateway my-gateway-ipv6

# Verificar serviços
kubectl get svc -n kube-system | grep cilium
kubectl get svc -n monitoring | grep grafana

# Testar conectividade interna
kubectl top nodes
```
