terraform {
    required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.10.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "Common-RG"  #Shd be created before 
    storage_account_name = "mywebsitestorage"  #Shd be created before
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}





