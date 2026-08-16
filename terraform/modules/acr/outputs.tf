output "acr_id" {
  description = "Registry resource ID (used for the AKS AcrPull assignment)."
  value       = azurerm_container_registry.main.id
}

output "login_server" {
  description = "Registry login server FQDN."
  value       = azurerm_container_registry.main.login_server
}
