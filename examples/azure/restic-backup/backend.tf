
#############################################################################
# BACKENDS
#############################################################################

terraform {
  backend "azurerm" {
  }

  required_providers {
    azurerm = {
      version = "=3.29.1"
    }

  }
  
}