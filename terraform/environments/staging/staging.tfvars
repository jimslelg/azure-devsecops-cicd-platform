environment        = "staging"
location           = "canadacentral"
vnet_address_space = ["10.20.0.0/16"]
aks_subnet_prefix  = "10.20.1.0/24"

aks_node_count         = 2
aks_node_vm_size       = "Standard_D2s_v5"
aks_availability_zones = []

acr_sku = "Standard"

# Corporate egress + Azure DevOps agent ranges (placeholders, set per org).
api_server_authorized_ranges = ["203.0.113.0/24"]
