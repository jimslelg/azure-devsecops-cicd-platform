output "resource_group_name" {
  description = "Environment resource group."
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "AKS cluster name, consumed by deploy stages."
  value       = module.aks.cluster_name
}

output "acr_login_server" {
  description = "ACR login server, consumed by build stages."
  value       = module.acr.login_server
}

output "key_vault_name" {
  description = "Key Vault backing this environment's variable group."
  value       = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  description = "Key Vault URI for workload configuration."
  value       = module.keyvault.key_vault_uri
}

output "pipeline_identity_client_id" {
  description = "Client ID of the pipeline's federated (OIDC) identity."
  value       = module.identity.pipeline_identity_client_id
}

output "workload_identity_client_id" {
  description = "Client ID the orders-api pod uses for workload identity."
  value       = module.identity.workload_identity_client_id
}

output "oidc_issuer_url" {
  description = "AKS OIDC issuer URL, needed to federate the workload identity."
  value       = module.aks.oidc_issuer_url
}
