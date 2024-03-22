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
  pm_api_url  = var.pm_api_base_url
  pm_user     = var.pm_user
  pm_password = var.pm_password
  #pm_api_token_id       = var.pm_api_token_id
  #pm_api_token_secret   = var.pm_api_token_secret

  pm_log_enable = true
  pm_log_file   = "terraform-plugin-proxmox.log"
  pm_debug      = true
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }

}