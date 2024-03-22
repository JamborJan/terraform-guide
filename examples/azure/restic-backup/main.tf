#############################################################################
# Ressources
#
# Azure Blopp Storage to save the data
# ACI restic container to check and maintain backup snapshots
#
#############################################################################

#############################################################################
# RESOURCES DEFAULT
#############################################################################

resource "azurerm_resource_group" "default" {
    name     = local.full_rg_name
    location = var.location
}

#############################################################################
# Storage Account & Storage Share
#############################################################################
resource "azurerm_storage_account" "default" {
    name                      = var.storage_name[terraform.workspace]
    resource_group_name       = azurerm_resource_group.default.name
    location                  = azurerm_resource_group.default.location
    account_kind              = "Storage" # defaults "StorageV2"
    account_tier              = "Standard"
    account_replication_type  = "LRS"
    enable_https_traffic_only = "true"
    min_tls_version           = "TLS1_2"

    lifecycle {
      create_before_destroy = false
      prevent_destroy = true
      # Conditions not yet allowed here, see: https://github.com/hashicorp/terraform/issues/3116
      # prevent_destroy = "${terraform.workspace == "PRD" ? true : false}"
    }

    tags = {
      Environment = terraform.workspace
      Owner = var.tag_owner
      ApplicationName = var.tag_application_name[terraform.workspace]
      CostCenter = var.tag_costcenter
      DR = var.tag_dr
    }
}

#############################################################################
# RESOURCES ACI restic
#############################################################################

resource "azurerm_container_group" "default" {
  name                = join("-", [terraform.workspace, var.tag_application_name[terraform.workspace]])
  location            = "${azurerm_resource_group.default.location}"
  resource_group_name = "${azurerm_resource_group.default.name}"
  ip_address_type     = "None"
  dns_name_label      = var.tag_application_name[terraform.workspace]
  os_type             = "Linux"

  restart_policy      = "Never"

  container {
    name     = "restic"
    image    = var.restic_image[terraform.workspace]
    cpu      = "0.2"
    memory   = "0.1"
    commands = ["sh","-c","restic forget --keep-last 1 --prune"]
    
    environment_variables = {
        AZURE_ACCOUNT_NAME = azurerm_storage_account.default.name,
        RESTIC_REPOSITORY = "${var.RESTIC_REPOSITORY[terraform.workspace]}"
    }

    secure_environment_variables = {
        AZURE_ACCOUNT_KEY = azurerm_storage_account.default.primary_access_key,
        RESTIC_PASSWORD = "${var.RESTIC_PASSWORD}"
    }

  }

  tags = {
    Environment = terraform.workspace
    Owner = var.tag_owner
    ApplicationName = var.tag_application_name[terraform.workspace]
    CostCenter = var.tag_costcenter
    DR = var.tag_dr
  }
}
