
# Módulo `network`

Cria redes virtuais Libvirt com suporte opcional a IPv4 e IPv6, DHCP e modo de encaminhamento configurável.

## Responsabilidade

Este módulo:
- Cria redes Libvirt com bridge dedicada (`br-<nome>`, truncada em 15 caracteres)
- Configura endereçamento IPv4 **ou** IPv6 (ou ambos)
- Ativa DHCP condicionalmente por protocolo
- Define modo de encaminhamento: `"nat"` ou `"isolated"`
- Controla inicialização automática (`autostart`)

## O que este módulo **não faz**
- Validar se o valor de `mode` é válido (aceita qualquer string; valores inválidos causam erro no provider)
- Garantir unicidade de nomes de rede (colisões não são detectadas)
- Criar redes sem pelo menos um bloco de IP (IPv4 ou IPv6) — isso causa falha no provider Libvirt
- Truncar nomes de rede (apenas o nome da bridge é truncado)

## Entrada esperada

A variável `networks` deve ser uma lista de objetos com os seguintes campos:

| Campo | Tipo | Obrigatório | Padrão | Observação |
|------|------|-------------|--------|-----------|
| `name` | `string` | Sim | — | Nome da rede; usado como identificador e no domínio DNS interno |
| `mode` | `string` | Sim | — | `"nat"` habilita forward e `"isolated"` desativa |
| `autostart` | `bool` | Sim | — | Se a rede inicia com o host |
| `ipv4_address` | `string` | Condicional | — | Endereço IPv4 da rede (ex: `"192.168.100.1"`) |
| `ipv4_prefix` | `number` | Se IPv4 ativo | — | Prefixo CIDR (0–32) |
| `ipv4_dhcp_enabled` | `bool` | Não | `false` | Ativa DHCP IPv4 |
| `ipv4_dhcp_start` / `end` | `string` | Se DHCP IPv4 ativo | — | Faixa de concessão |
| `ipv6_address` | `string` | Condicional | — | Endereço IPv6 (ex: `"fd00::1"`) |
| `ipv6_prefix` | `number` | Se IPv6 ativo | — | Prefixo CIDR (0–128) |
| `ipv6_dhcp_enabled` | `bool` | Não | `false` | Ativa DHCP IPv6 |
| `ipv6_dhcp_start` / `end` | `string` | Se DHCP IPv6 ativo | — | Faixa de concessão |

> ⚠️ **Requisito crítico**:  
> Pelo menos **um** dos blocos (`ipv4_address` ou `ipv6_address`) deve ser definido.  
> Caso contrário, o recurso `libvirt_network` falhará com "no IP addresses defined".

## Comportamentos técnicos

- **Nome da bridge**: gerado como `br-${name}`, truncado em **15 caracteres** (limite do kernel Linux)
- **Forwarding**: ativado apenas se `mode != "isolated"`
- **Domínio DNS**: sempre definido como `name = net.name`
- **DHCP**: incluído somente se `*_dhcp_enabled == true` e os campos `start`/`end` estiverem presentes

## Exemplo de uso

```hcl
module "network" {
  source   = "./modules/network"
  networks = var.networks
}
```

## Saídas

- `networks`: mapa indexado pelo nome da rede, contendo:
  - `id`: UUID do Libvirt
  - `name`: nome da rede
  - `bridge`: nome real da interface bridge criada (ex: `"br-wan"`)

Útil para depuração ou integração com outros módulos (ex: vincular interfaces de VM).

## Limitações conhecidas

- Nomes de rede longos (>12 caracteres) geram bridges truncadas (ex: `br-clientes_ti-net` → `br-clientes_ti-`)
- Não há validação de consistência (ex: prefixo IPv4 fora de [0,32])
- Modo `"isolated"` desativa totalmente o forward; outros modos usam o padrão do Libvirt (`nat`)
