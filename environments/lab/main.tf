module "orchestration" {
  source = "../../modules/orchestration"

  # Dados de infraestrutura
  networks = var.networks
  vms      = var.vms

  # Configuração do ambiente
  ssh_public      = var.ssh_public
  storage_pool    = var.storage_pool
  image_directory = var.image_directory
}
