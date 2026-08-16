output "key_vault_id" {
  description = "Key Vault resource ID."
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Key Vault name (linked to the ADO variable group)."
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Key Vault URI for SDK access."
  value       = azurerm_key_vault.main.vault_uri
}
