
#############################################################################
# BACKENDS
#############################################################################

terraform {
  backend "azurerm" {
  }

  required_providers {
    azurerm = {
      version = "=3.21.1"
    }

    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }

  }

}