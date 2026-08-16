data "azurerm_client_config" "current" {}

resource "random_string" "kv_suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  # Vault names are globally unique, <= 24 chars, alphanumeric + hyphen.
  vault_name = substr("kv-${var.name_prefix}-${random_string.kv_suffix.result}", 0, 24)
}

resource "azurerm_key_vault" "main" {
  name                = local.vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = var.tags

  # RBAC authorization instead of access policies: assignments are auditable
  # role assignments, and the same model covers pipelines and workloads.
  enable_rbac_authorization = true

  purge_protection_enabled   = true
  soft_delete_retention_days = 30

  network_acls {
    default_action = "Allow" # tightened to Deny + private endpoint on the roadmap
    bypass         = "AzureServices"
  }
}

# Pipeline + workload identities read secrets; nothing gets write access here —
# secret writes happen through Terraform or break-glass humans with PIM.
resource "azurerm_role_assignment" "secret_readers" {
  count = length(var.reader_principal_ids)

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.reader_principal_ids[count.index]
}
