Define the Cluster
resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "example-aks-cluster"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  dns_prefix          = "exampleaks"    #dns_prefix is a "address" of your Kubernetes API server.

  identity {
    type = "SystemAssigned"
  }

  # This creates your single "System" node pool
  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_DS2_v2"
    node_count = 1  # Set to 1 for a single node
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }
}