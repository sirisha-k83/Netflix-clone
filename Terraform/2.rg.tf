resource "azurerm_resource_group" "rg1" {
  name     = var.rg1_name
  location = var.location
  tags = {
    Env = var.environment
  }
}