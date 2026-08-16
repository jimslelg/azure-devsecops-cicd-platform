locals {
  # ACR names must be globally unique, alphanumeric, 5-50 chars.
  registry_name = replace("acr${var.name_prefix}", "-", "")
}

resource "azurerm_container_registry" "main" {
  name                = local.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  tags                = var.tags

  # Zero stored credentials: pushes and pulls use managed identities only.
  admin_enabled = false

  # Quarantine/retention/trust policies require Premium; content trust is
  # deliberately NOT used — image integrity is enforced by deploying digests.
  dynamic "retention_policy" {
    for_each = var.sku == "Premium" ? [1] : []
    content {
      enabled = true
      days    = 30
    }
  }
}

# The pipeline identity pushes scanned images.
resource "azurerm_role_assignment" "pipeline_push" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = var.pusher_principal_id
}
