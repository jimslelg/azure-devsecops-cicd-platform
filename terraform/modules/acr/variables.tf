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

variable "sku" {
  description = "Registry SKU (Basic, Standard, Premium)."
  type        = string
}

variable "pusher_principal_id" {
  description = "Principal granted AcrPush (the pipeline identity)."
  type        = string
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
