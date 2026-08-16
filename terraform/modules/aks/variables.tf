variable "name_prefix" {
  description = "Naming prefix (project-environment)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy into."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version."
  type        = string
}

variable "node_count" {
  description = "Default node pool size."
  type        = number
}

variable "node_vm_size" {
  description = "Default node pool VM size."
  type        = string
}

variable "availability_zones" {
  description = "Zones for the default node pool (empty = non-zonal)."
  type        = list(string)
  default     = []
}

variable "subnet_id" {
  description = "Subnet for cluster nodes."
  type        = string
}

variable "acr_id" {
  description = "ACR resource ID the kubelet identity pulls from."
  type        = string
}

variable "api_server_authorized_ranges" {
  description = "CIDRs allowed to reach the API server (empty = open)."
  type        = list(string)
  default     = []
}

variable "admin_principal_id" {
  description = "Principal granted RBAC Cluster Admin (the pipeline identity)."
  type        = string
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
