#############################################################################
# PROVIDERS
#############################################################################

provider "azurerm" {
    features {
        key_vault {
            recover_soft_deleted_key_vaults = false # defaults to true
            purge_soft_delete_on_destroy    = false # defaults to true
        }
    }
}