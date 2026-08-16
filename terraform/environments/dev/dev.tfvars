environment        = "dev"
location           = "canadacentral"
vnet_address_space = ["10.10.0.0/16"]
aks_subnet_prefix  = "10.10.1.0/24"

aks_node_count         = 1
aks_node_vm_size       = "Standard_B2s"
aks_availability_zones = []

acr_sku = "Basic"

# Dev API server intentionally open for fast iteration; staging/prod restrict.
api_server_authorized_ranges = []
