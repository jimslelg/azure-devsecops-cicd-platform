# Two user-assigned identities per environment:
#  - pipeline: assumed by Azure DevOps via workload identity federation (OIDC);
#    it is the only identity Terraform/deploy stages run as. No client secrets exist.
#  - workload: assumed by the orders-api pod via AKS workload identity to read Key Vault.

resource "azurerm_user_assigned_identity" "pipeline" {
  name                = "id-${var.name_prefix}-pipeline"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-${var.name_prefix}-workload"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Federation for the Azure DevOps service connection (one per environment).
# The subject/issuer pair is what Azure DevOps presents when the service
# connection is configured for workload identity federation; the placeholder
# issuer is replaced by the value ADO generates when the connection is created.
resource "azurerm_federated_identity_credential" "ado" {
  name                = "fic-${var.name_prefix}-ado"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.pipeline.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "${var.ado_organization_url}/_oidc"
  subject             = "sc://${trimprefix(var.ado_organization_url, "https://dev.azure.com/")}/${var.name_prefix}/${var.name_prefix}-connection"
}

# Federation for GitHub Actions (kept for portability; the primary CI is ADO).
resource "azurerm_federated_identity_credential" "github" {
  name                = "fic-${var.name_prefix}-github"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.pipeline.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_repository}:environment:${var.environment}"
}
