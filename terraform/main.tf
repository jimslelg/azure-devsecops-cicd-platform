locals {
  name_prefix = "${var.project}-${var.environment}"

  tags = merge(
    {
      project     = var.project
      environment = var.environment
      managed_by  = "terraform"
      repository  = var.github_repository
    },
    var.tags,
  )
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "./modules/network"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_address_space  = var.vnet_address_space
  aks_subnet_prefix   = var.aks_subnet_prefix
  tags                = local.tags
}

module "identity" {
  source = "./modules/identity"

  name_prefix          = local.name_prefix
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  github_repository    = var.github_repository
  environment          = var.environment
  ado_organization_url = var.ado_organization_url
  tags                 = local.tags
}

module "acr" {
  source = "./modules/acr"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  pusher_principal_id = module.identity.pipeline_identity_principal_id
  tags                = local.tags
}

module "keyvault" {
  source = "./modules/keyvault"

  name_prefix          = local.name_prefix
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  reader_principal_ids = [module.identity.pipeline_identity_principal_id, module.identity.workload_identity_principal_id]
  tags                 = local.tags
}

module "aks" {
  source = "./modules/aks"

  name_prefix                  = local.name_prefix
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  kubernetes_version           = var.kubernetes_version
  node_count                   = var.aks_node_count
  node_vm_size                 = var.aks_node_vm_size
  availability_zones           = var.aks_availability_zones
  subnet_id                    = module.network.aks_subnet_id
  acr_id                       = module.acr.acr_id
  api_server_authorized_ranges = var.api_server_authorized_ranges
  admin_principal_id           = module.identity.pipeline_identity_principal_id
  tags                         = local.tags
}
