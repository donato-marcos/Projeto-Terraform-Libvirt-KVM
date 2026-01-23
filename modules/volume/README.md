
# Módulo `volume`

Cria volumes de disco Libvirt para máquinas virtuais, com ou sem imagem base (*backing store*).

## Responsabilidade

Este módulo:
- Cria volumes no storage pool especificado (`var.storage_pool`)
- Suporta discos vazios ou baseados em imagens pré-existentes
- Deriva o formato do disco (`qcow2` ou `raw`) da configuração fornecida
- Nomeia cada volume como `<vm_name>-<disk_name>`

## O que este módulo **não faz**
- Validar se a imagem base existe em `image_directory`
- Garantir unicidade global de nomes de volume (colisões silenciosas ocorrem se duas VMs tiverem mesmo nome + mesmo `disk.name`)
- Tratar o campo `bootable` — ele é aceito, mas **ignorado** (responsabilidade do módulo de domínio)
- Criar volumes em múltiplos pools diferentes (todos usam o mesmo `storage_pool`)

## Entrada esperada

A variável `vms` deve ser um mapa onde cada VM contém uma lista `disks`. Cada disco aceita:

| Campo | Tipo | Obrigatório | Padrão | Observação |
|------|------|-------------|--------|-----------|
| `name` | `string` | Sim | — | Usado na composição do nome do volume |
| `size_gb` | `number` | Sim | — | Tamanho em gibibytes (GiB) |
| `backing_store.image` | `string` | Condicional | — | Nome do arquivo de imagem base (ex: `"ubuntu-24-cloud.x86_64.qcow2"`) |
| `backing_store.format` | `string` | Não | `"qcow2"` | Formato da imagem base |
| `format` | `string` | Não | `"qcow2"` | Usado apenas se não houver `backing_store` |

> ⚠️ **Requisito crítico**:  
> O diretório `image_directory` **deve corresponder fisicamente** ao caminho do `storage_pool` Libvirt.  
> Exemplo: se `storage_pool = "default"` aponta para `/home/user/vm`, então `image_directory` deve ser `/home/user/vm`.

## Comportamentos técnicos

- **Nome do volume**: sempre `<vm_name>-<disk_name>` (ex: `"SdcSVR01-os"`)
- **Capacidade**: convertida internamente para bytes (`size_gb * 1024³`)
- **Formato**: prioriza `backing_store.format`, depois `disk.format`, senão `"qcow2"`
- **Backing store**: caminho completo é `${var.image_directory}/${image}`

## Exemplo de uso

```hcl
module "volume" {
  source          = "./modules/volume"
  vms             = var.vms
  image_directory = var.image_directory
  storage_pool    = var.storage_pool
}
```

## Saídas

- `volumes`: mapa indexado por `<vm_name>-<disk_name>`, contendo:
  - `id`: UUID do volume no Libvirt
  - `name`: nome do volume
  - `pool`: nome do storage pool

Essa saída é usada pelos módulos `domain_linux` e `domain_windows` para anexar os discos corretos.

## Limitações conhecidas

- Não há verificação prévia da existência da imagem base — falha apenas na aplicação
- Todos os volumes são criados no mesmo pool (`storage_pool`)
- Nomes longos de VM + disco podem exceder limites do sistema de arquivos (raro, mas possível)
- O campo `bootable` é armazenado nos dados da VM, mas **não influencia este módulo**
