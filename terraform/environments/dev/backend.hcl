# terraform init -backend-config=environments/dev/backend.hcl
resource_group_name  = "rg-devsecops-tfstate"
storage_account_name = "stdevsecopstfstate"
container_name       = "tfstate"
key                  = "dev.terraform.tfstate"
use_oidc             = true
use_azuread_auth     = true
