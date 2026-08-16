output "vnet_id" {
  description = "VNet resource ID."
  value       = azurerm_virtual_network.main.id
}

output "aks_subnet_id" {
  description = "AKS node subnet resource ID."
  value       = azurerm_subnet.aks.id
}
