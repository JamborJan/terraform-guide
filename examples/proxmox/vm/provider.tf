#############################################################################
# PROVIDERS
#############################################################################

provider "azurerm" {
    features {
        key_vault {
            recover_soft_deleted_key_vaults = false #defaults to true
        }
    }
}

provider "proxmox" {
  pm_api_url            = "https://proxmox.watt.jambor.pro/api2/json"
  pm_debug              = true
  pm_api_token_id       = "terraform-prov@pve!terraform-token"
  pm_api_token_secret   = "82c9a543-8a04-4935-b715-ab2f2c478b54"
}