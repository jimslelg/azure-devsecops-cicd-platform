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

variable "environment" {
  description = "Environment name, used in federated credential subjects."
  type        = string
}

variable "github_repository" {
  description = "GitHub repo (org/name) trusted by the federated credential."
  type        = string
}

variable "ado_organization_url" {
  description = "Azure DevOps organization URL for the service connection issuer."
  type        = string
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
