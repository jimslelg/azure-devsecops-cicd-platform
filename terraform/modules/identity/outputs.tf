output "pipeline_identity_principal_id" {
  description = "Principal ID of the pipeline (OIDC) identity, for RBAC assignments."
  value       = azurerm_user_assigned_identity.pipeline.principal_id
}

output "pipeline_identity_client_id" {
  description = "Client ID of the pipeline identity, used by the ADO service connection."
  value       = azurerm_user_assigned_identity.pipeline.client_id
}

output "workload_identity_principal_id" {
  description = "Principal ID of the workload identity."
  value       = azurerm_user_assigned_identity.workload.principal_id
}

output "workload_identity_client_id" {
  description = "Client ID annotated on the orders-api service account."
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "workload_identity_id" {
  description = "Resource ID of the workload identity."
  value       = azurerm_user_assigned_identity.workload.id
}
