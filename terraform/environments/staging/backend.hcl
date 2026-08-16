# terraform init -backend-config=environments/staging/backend.hcl
resource_group_name  = "rg-devsecops-tfstate"
storage_account_name = "stdevsecopstfstate"
container_name       = "tfstate"
key                  = "staging.terraform.tfstate"
use_oidc             = true
use_azuread_auth     = true
