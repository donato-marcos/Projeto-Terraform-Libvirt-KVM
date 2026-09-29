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

### Passo 3: Aplicar root-apps.yaml
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

