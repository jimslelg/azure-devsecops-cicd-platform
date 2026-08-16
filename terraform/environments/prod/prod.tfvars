environment        = "prod"
location           = "canadacentral"
vnet_address_space = ["10.30.0.0/16"]
aks_subnet_prefix  = "10.30.1.0/24"

aks_node_count         = 3
aks_node_vm_size       = "Standard_D4s_v5"
aks_availability_zones = ["1", "2", "3"]

acr_sku = "Premium"

# Corporate egress + Azure DevOps agent ranges (placeholders, set per org).
api_server_authorized_ranges = ["203.0.113.0/24", "198.51.100.0/24"]
