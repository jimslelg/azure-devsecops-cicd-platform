variable "environment" {
  description = "Environment name; drives naming, sizing, and tags."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "canadacentral"
}

variable "project" {
  description = "Project slug used as the naming prefix."
  type        = string
  default     = "devsecops"
}

variable "vnet_address_space" {
  description = "Address space of the environment VNet."
  type        = list(string)
}

variable "aks_subnet_prefix" {
  description = "Address prefix for the AKS node subnet."
  type        = string
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version (minor version; patch managed by Azure)."
  type        = string
  default     = "1.29"
}

variable "aks_node_count" {
  description = "Node count of the default node pool."
  type        = number
}

variable "aks_node_vm_size" {
  description = "VM size of the default node pool."
  type        = string
}

variable "aks_availability_zones" {
  description = "Availability zones for the default node pool (empty = non-zonal)."
  type        = list(string)
  default     = []
}

variable "acr_sku" {
  description = "Azure Container Registry SKU."
  type        = string

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "acr_sku must be Basic, Standard, or Premium."
  }
}

variable "api_server_authorized_ranges" {
  description = "CIDRs allowed to reach the AKS API server. Empty list = open (dev only)."
  type        = list(string)
  default     = []
}

variable "github_repository" {
  description = "GitHub repo (org/name) trusted by the federated identity credential."
  type        = string
  default     = "jimslelg/azure-devsecops-cicd-platform"
}

variable "ado_organization_url" {
  description = "Azure DevOps organization URL used as the OIDC issuer audience for service connections."
  type        = string
  default     = "https://dev.azure.com/jimslelg"
}

variable "tags" {
  description = "Extra tags merged onto the standard tag set."
  type        = map(string)
  default     = {}
}
