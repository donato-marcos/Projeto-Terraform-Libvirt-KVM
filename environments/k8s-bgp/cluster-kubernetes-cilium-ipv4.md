
># Laboratório Kubernetes com Cilium e GatewayAPI

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
| `k8s-master01` | 2 | 2.5 GB | `192.168.0.65` | `172.16.200.65` | `172.16.201.65` |
| `k8s-worker01` | 2 | 3.0 GB | `192.168.0.66` | `172.16.200.66` | `172.16.201.66` |
| `k8s-worker02` | 2 | 3.0 GB | `192.168.0.67` | `172.16.200.67` | `172.16.201.67` |

> **Nota de Rede:** O IP `192.168.0.69` será reservado para o **Cilium LoadBalancer**, atuando como VIP único para serviços externos. O anúncio L2 será feito na interface **`enp1s0`**.

---

## Provisionamento com Terraform (Opcional)

Se estiver usando `Libvirt+KVM`, pode usar o **[Projeto-Terraform-Libvirt-KVM](https://github.com/donato-marcos/Projeto-Terraform-Libvirt-KVM)** para automatizar a criação da infra.

### 1. Definição das Redes (`networks.auto.tfvars`)

```hcl
# networks.auto.tfvars:
networks = [
  {
    name      = "k8s-cluster"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "172.16.200.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
  },
  {
    name      = "k8s-storage"
    mode      = "isolated"
    autostart = true

    ipv4_address      = "172.16.201.1"
    ipv4_prefix       = 24
    ipv4_dhcp_enabled = false
  }
]
```

### 2. Definição das VMs (`vm.auto.tfvars`)

Note a ordem das redes definidas, que resulta nas interfaces `enp1s0`, `enp2s0` e `enp3s0` dentro das VMs.

> AJUSTE O ENDEREÇAMENTO IP NA INTERFACE `enp1s0` QUE VAI USAR A BRIDGE

```hcl
# vm.auto.tfvars:
vms = {

  # Servidor kubernetes control-plane
  "k8s-master01" = {
    os_type        = "linux"
    vcpus          = 2
    current_memory = 2560
    memory         = 3072
    firmware       = "efi"
    video_model    = "virtio"
    graphics       = "vnc"
    running        = true
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
      { name = "bridge0", ipv4_address = "192.168.0.65", ipv4_prefix = 24, ipv4_gateway = "192.168.0.1", dns_servers  = ["8.8.8.8"], wait_for_lease = false},
      { name = "k8s-cluster", ipv4_address = "172.16.200.65", ipv4_prefix = 24, wait_for_lease = false},
      { name = "k8s-storage", ipv4_address = "172.16.201.65", ipv4_prefix = 24, wait_for_lease = false}
    ]
  },

  # Servidor kubernetes worker
  "k8s-worker01" = {
    os_type        = "linux"
    vcpus          = 2
    current_memory = 2048
    memory         = 3072
    firmware       = "efi"
    video_model    = "virtio"
    graphics       = "vnc"
    running        = true
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
      { name = "bridge0", ipv4_address = "192.168.0.66", ipv4_prefix = 24, ipv4_gateway = "192.168.0.1", dns_servers  = ["8.8.8.8"], wait_for_lease = false},
      { name = "k8s-cluster", ipv4_address = "172.16.200.66", ipv4_prefix = 24, wait_for_lease = false},
      { name = "k8s-storage", ipv4_address = "172.16.201.66", ipv4_prefix = 24, wait_for_lease = false}
    ]
  },

  # Servidor kubernetes worker
  "k8s-worker02" = {
    os_type        = "linux"
    vcpus          = 2
    current_memory = 2048
    memory         = 3072
    firmware       = "efi"
    video_model    = "virtio"
    graphics       = "vnc"
    running        = true
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
      { name = "bridge0", ipv4_address = "192.168.0.67", ipv4_prefix = 24, ipv4_gateway = "192.168.0.1", dns_servers  = ["8.8.8.8"], wait_for_lease = false},
      { name = "k8s-cluster", ipv4_address = "172.16.200.67", ipv4_prefix = 24, wait_for_lease = false},
      { name = "k8s-storage", ipv4_address = "172.16.201.67", ipv4_prefix = 24, wait_for_lease = false}
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
#net.ipv6.conf.all.forwarding = 1
#net.ipv6.conf.default.forwarding = 1
#net.ipv6.conf.enp1s0.forwarding = 1

# Garante IPv6 ativo nas interfaces
#net.ipv6.conf.all.disable_ipv6 = 0
#net.ipv6.conf.default.disable_ipv6 = 0
#net.ipv6.conf.enp1s0.disable_ipv6 = 0
#net.ipv6.conf.lo.disable_ipv6 = 0

# Aceita RA para manter o Default Gateway da VM mesmo como Router (fowarding=1)
#net.ipv6.conf.enp1s0.accept_ra = 2

# Aceita NDP
#net.ipv6.conf.all.proxy_ndp = 1
#net.ipv6.conf.default.proxy_ndp = 1
#net.ipv6.conf.enp1s0.proxy_ndp = 1

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

---

## Inicialização do Cluster

### 1. Control-Plane (`k8s-master01`)

Crie `kubeadm-config.yaml`:
```yaml
cat > kubeadm-config.yaml << 'EOF'
# kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration

localAPIEndpoint:
  advertiseAddress: "172.16.200.65"
  bindPort: 6443
  
nodeRegistration:
  criSocket: "unix:///run/containerd/containerd.sock"
  kubeletExtraArgs:
    - name: "node-ip"
      value: "172.16.200.65"
    
skipPhases:
  - addon/kube-proxy
  
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration

clusterName: kubernetes
kubernetesVersion: "v1.36.0"
certificatesDir: /etc/kubernetes/pki
controlPlaneEndpoint: "172.16.200.65:6443"

networking:
  podSubnet: "10.244.0.0/16"
  serviceSubnet: "10.96.0.0/12"
  dnsDomain: "cluster.local"

apiServer:
  certSANs:
    - "172.16.200.65"
    - "192.168.0.65"
  extraArgs:
    - name: "bind-address"
      value: "::"
    - name: "advertise-address"
      value: "172.16.200.65"

controllerManager:
  extraArgs:
    - name: "bind-address"
      value: "::"
    - name: "allocate-node-cidrs"
      value: "true"
    - name: "node-cidr-mask-size-ipv4"
      value: "24"

scheduler:
  extraArgs:
    - name: "bind-address"
      value: "::"

etcd:
  local:
    dataDir: /var/lib/etcd
    extraArgs:
      - name: "listen-client-urls"
        value: "https://172.16.200.65:2379"
      - name: "advertise-client-urls"
        value: "https://172.16.200.65:2379"
      - name: "listen-peer-urls"
        value: "https://172.16.200.65:2380"
      - name: "initial-advertise-peer-urls"
        value: "https://172.16.200.65:2380"
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
    apiServerEndpoint: "172.16.200.65:6443"
    token: "<TOKEN_GERADO_NO_MASTER>"
    caCertHashes:
      - "sha256:<HASH>"

nodeRegistration:
  criSocket: "unix:///run/containerd/containerd.sock"
  kubeletExtraArgs:
    - name: "node-ip"
      value: "172.16.200.66"
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
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml

# CRD para Service Monitor
#https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
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
# cilium-values.yaml
# --- Kubernetes API ---
k8sServiceHost: "172.16.200.65"
k8sServicePort: 6443

cluster:
  name: k8s-cluster
  id: 1

# --- IPv4/IPv6 (Dual-Stack) ---
ipv4:
  enabled: true
enableIPv4Masquerade: true

ipv6:
  enabled: false
enableIPv6Masquerade: false

#masqueradeInterfaces: "enp1s0"

# --- kube-proxy replacement ---
# Substitui totalmente o kube-proxy usando eBPF
kubeProxyReplacement: true
#hostFirewall:
#  enabled: true # pode deixar o lab mais complicado, cuidado.

# --- Datapath & Roteamento Nativo ---
# Inclui ambas as interfaces relevantes: Cluster (para Pods)
#devices: ""

#extraConfig:
#  enable-ipv6-ndp: "true"
#  ipv6-mcast-device: "enp1s0"
  
routingMode: native
autoDirectNodeRoutes: true

# Define os CIDRs globais para roteamento nativo (opcional se o IPAM já estiver correto, mas bom para explícito)
ipv4NativeRoutingCIDR: "10.244.0.0/16"
#ipv6NativeRoutingCIDR: "fd00:10:244::/56"

# --- IPAM (Gerenciamento de IPs) ---
ipam:
  mode: kubernetes
  operator:
    # Pool IPv4: /16 dividido em /24 por nó
    clusterPoolIPv4PodCIDRList:
      - "10.244.0.0/16"
    clusterPoolIPv4MaskSize: 24
    # Pool IPv6: /56 dividido em /64 por nó
    #clusterPoolIPv6PodCIDRList:
    #  - "fd00:10:244::/56"
    #clusterPoolIPv6MaskSize: 64

#tunnel: disabled

# --- L2 Announcements (Substitui MetalLB) ---
l2announcements:
  enabled: true

l2NeighDiscovery:
  enabled: true

loadBalancer:
  standalone: false
  algorithm: maglev
  mode: dsr
  acceleration: best-effort
  dsrDispatch: opt
  serviceTopology: true
  l7:
    backend: envoy
    ports: []

#externalIPs:
#  enabled: true

#nodePort:
#  enabled: true

#MTU: 1400

# --- Gateway API (Substitui Ingress-Nginx) ---
gatewayAPI:
  enabled: true
#  gatewayClass:
#    create: "true"

envoy:
  enabled: true

# --- Hubble (Observabilidade) ---
hubble:
  enabled: true
  relay:
    enabled: true
  ui:
    enabled: true
  tls:
    enabled: false
  peerService:
    clusterDomain: "cluster.local"
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
#    serviceMonitor:
#      enabled: true

operator:
  prometheus:
    enabled: true
    
# --- Prometheus Integrado (Opcional) ---
# Deixado falso pois você usará a stack kube-prometheus separada
prometheus:
  enabled: false

# --- Performance e BPF ---
bpf:
  masquerade: true
  hostLegacyRouting: false
  tproxy: true

# --- Performance BIG TCP (Precisa verificar se suas máquinas suportam ) ---
# Comando: # ethtool -k <NIC> | grep -E "segmentation|receive"
# TSO, GSO e GRO devem estar `on`
enableIPv4BIGTCP: true
#enableIPv6BIGTCP: true
EOF
```

Instale o CNI Cilium:
```bash
helm repo add cilium https://helm.cilium.io/
helm repo update

helm install cilium cilium/cilium \
--version 1.19.4 \
--namespace kube-system \
-f cilium-values.yaml
```

Aguarde a instalação:
```bash
cilium status --wait
```

> **PODE DEMORAR BASTANTE**

> **A PARTIR DAQUI, você pode querer automatizar utilizando o [ArgoCD](instalar-argocd.md)**

### 3. Configuração do LoadBalancer L2 e Gateway

Crie o arquivo `l2-ipv4-pool.yaml`:

```yaml
cat > l2-ipv4-pool.yaml << 'EOF'
#l2-ipv4-pool.yaml
apiVersion: "cilium.io/v2"
kind: CiliumLoadBalancerIPPool
metadata:
  name: public-pool-ipv4
spec:
  blocks:
    - cidr: "192.168.0.69/32"
---
apiVersion: "cilium.io/v2alpha1"
kind: CiliumL2AnnouncementPolicy
metadata:
  name: public-announcement-ipv4
spec:
  nodeSelector:
    matchLabels:
      kubernetes.io/os: linux
  interfaces:
    - ^enp1s0$
  externalIPs: true
  loadBalancerIPs: true
EOF
```
E aplique com:
```bash
kubectl apply -f l2-ipv4-pool.yaml
```

Crie o arquivo `gateway-ipv4.yaml`:
```yaml
cat > gateway-ipv4.yaml << 'EOF'
# gateway-ipv4.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: public-gateway-ipv4
  namespace: default
spec:
  gatewayClassName: cilium
  addresses:
  - type: IPAddress
    value: "192.168.0.69"
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
EOF
```

E aplique com:
```bash
kubectl apply -f gateway-ipv4.yaml
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
cat > monitoring-httproute.yaml << 'EOF'
# monitoring-httproute.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: hubble-ui-route
  namespace: kube-system
spec:
  parentRefs:
  - name: public-gateway-ipv4
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
  - name: public-gateway-ipv4
    namespace: default
  hostnames:
  - "grafana.aesthar.com.br"
  rules:
  - backendRefs:
    - name: monitoring-grafana
      port: 80
EOF
```
E aplique com:
```bash
kubectl apply -f monitoring-httproute.yaml
```


### Acesso Local

No seu host Fedora, edite `/etc/hosts`:
```bash
echo "192.168.0.69 hubble.aesthar.com.br" | sudo tee -a /etc/hosts
echo "192.168.0.69 grafana.aesthar.com.br" | sudo tee -a /etc/hosts

```

Acesse:
*   **Hubble:** http://hubble.aesthar.com.br
*   **Grafana:** http://grafana.aesthar.com.br (admin / alunofatec)

---

## Validação Final

```bash
# Verificar se o Cilium está saudável
cilium status

# Verificar se o IP 192.168.0.69 foi atribuído ao Gateway
kubectl get gateway public-gateway-ipv4

# Verificar serviços
kubectl get svc -n kube-system | grep cilium
kubectl get svc -n monitoring | grep grafana

# Testar conectividade interna
kubectl top nodes
```