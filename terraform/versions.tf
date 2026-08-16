terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Backend values are supplied per environment via
  #   terraform init -backend-config=environments/<env>/backend.hcl
  # so one root configuration serves all environments with isolated state.
  backend "azurerm" {}
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }

  # Pipeline auth uses workload identity federation (OIDC) — no client secret.
  use_oidc = true
}
