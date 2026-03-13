terraform {
    required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.10.0"
    }
  }

 backend "azurerm" {
   resource_group_name  = "AZB48SLB"
   storage_account_name = "londonstorageindia"
   container_name       = "tfstate"
   key                  = "aks.tfstate"
 }
}

provider "azurerm" {
 subscription_id = "4879f329-b467-46e8-9912-49f66c238cdd"
  features {}
}


