
#############################################################################
# BACKENDS
#############################################################################

terraform {
  backend "azurerm" {
  }

  required_providers {
    azurerm = {
      version = "=3.85.0"
    }

    proxmox = {
      source  = "TheGameProfi/proxmox"
      version = "2.9.15"
    }

  }

}