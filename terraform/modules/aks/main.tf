resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = "aks-${var.name_prefix}"
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  # RBAC via Entra ID; local accounts disabled so kubeconfigs cannot bypass AAD.
  local_account_disabled            = true
  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    # `managed` is deprecated in azurerm 3.x but still required to be true;
    # it disappears (defaulting to true) in provider v4 — drop it on upgrade.
    managed            = true
    azure_rbac_enabled = true
  }

  # Workload identity lets pods federate to Entra ID without secrets.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                = "system"
    node_count          = var.node_count
    vm_size             = var.node_vm_size
    vnet_subnet_id      = var.subnet_id
    zones               = length(var.availability_zones) > 0 ? var.availability_zones : null
    os_disk_type        = "Managed"
    enable_auto_scaling = false

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"
  }

  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ranges
    }
  }

  maintenance_window {
    allowed {
      day   = "Saturday"
      hours = [2, 3, 4]
    }
  }
}

# Kubelet pulls images with the cluster identity — no imagePullSecrets anywhere.
resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# The pipeline identity administers the cluster through Azure RBAC for Kubernetes.
resource "azurerm_role_assignment" "pipeline_admin" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.admin_principal_id
}
