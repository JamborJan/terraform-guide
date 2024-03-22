#############################################################################
# Resource group
#############################################################################

resource "azurerm_resource_group" "default" {
    name     = local.full_rg_name
    location = var.location["DE"].regionName
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
      #prevent_destroy = true
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

resource "azurerm_storage_share" "default-data" {
    name                 = join("-", [var.storage_share_name[terraform.workspace], "data"])
    storage_account_name = azurerm_storage_account.default.name
    quota                = 50
}

resource "azurerm_storage_share" "default-migration" {
    name                 = join("-", [var.storage_share_name[terraform.workspace], "migration"])
    storage_account_name = azurerm_storage_account.default.name
    quota                = 50
}

resource "azurerm_storage_share" "default-traefik" {
    name                 = join("-", [var.storage_share_name[terraform.workspace], "traefik"])
    storage_account_name = azurerm_storage_account.default.name
    quota                = 50
}

resource "azurerm_storage_share" "default-filebrowser" {
    name                 = join("-", [var.storage_share_name[terraform.workspace], "filebrowser"])
    storage_account_name = azurerm_storage_account.default.name
    quota                = 1
}

#############################################################################
# Write config files
#############################################################################

resource "local_file" "traefik-toml" {
    content     = <<-EOT
                  defaultEntryPoints = ["http", "https"]
                  [acceslog]
                  [entryPoints]
                    [entryPoints.http]
                      address = ":80"
                      [entryPoints.http.http]
                      [entryPoints.http.http.redirections]
                        [entryPoints.http.http.redirections.entryPoint]
                          to = "https"
                          scheme = "https"
                    [entryPoints.https]
                      address = ":443"
                    [entryPoints.https.http.tls]
                      certResolver = "le"
                  [log]
                    level="DEBUG"
                  [api]
                    dashboard = false
                    insecure = false
                  [providers]
                  [providers.file]
                    directory = "/etc/traefik/services"
                    watch = true
                  [certificatesResolvers.le.acme]
                    storage = "/acme.json"
                    email = "${var.tag_owner}"
                    # Once you get things working, you should remove that whole line altogether.
                    #caServer = "https://acme-staging-v02.api.letsencrypt.org/directory"
                    caServer = "https://acme-v02.api.letsencrypt.org/directory"
                    [certificatesResolvers.le.acme.tlsChallenge]
                  EOT
    
    filename = "traefik.toml"

    provisioner "local-exec" {
      command = "az storage file upload --account-name ${azurerm_storage_account.default.name} --account-key ${azurerm_storage_account.default.primary_access_key} --share-name ${azurerm_storage_share.default-traefik.name} --source \"traefik.toml\" --path \"traefik.toml\""
    }

}

resource "local_file" "nodered-toml" {
    content     = <<-EOT
                  [http]
                    # Add the router
                    [http.routers]
                      [http.routers.nodered]
                        entrypoints = ["https"]
                        middlewares = ["nodered-stripprefix", "nodered-auth"]
                        service = "nodered"
                        rule = "Host(`${join("", [var.tag_application_name[terraform.workspace], ".", var.location["DE"].regionCode ,".azurecontainer.io"])}`)"
                      [http.routers.nodered.tls]
                        certResolver = "le"
                      # middleware to strip the prefix
                      [http.middlewares]
                        [http.middlewares.nodered-stripprefix.stripprefix]
                          prefixes = ["/nodered"]
                        [http.middlewares.nodered-auth.basicauth]
                          users = ["${var.BASIC_AUTH_USER}"]
                      # Define how to reach an existing service on our infrastructure
                      [http.services]
                        [http.services.nodered]
                          [http.services.nodered.loadBalancer]
                            [[http.services.nodered.loadBalancer.servers]]
                              # As we are in the same container group, container can talk to each other through localhost or 127.0.0.1
                              url = "http://127.0.0.1:1880"
                  EOT
    
    filename = "nodered.toml"

    provisioner "local-exec" {
      command = "az storage directory create --account-name ${azurerm_storage_account.default.name} --account-key ${azurerm_storage_account.default.primary_access_key} --share-name ${azurerm_storage_share.default-traefik.name} --name \"services\" --output none"
    }

    provisioner "local-exec" {
      command = "az storage file upload --account-name ${azurerm_storage_account.default.name} --account-key ${azurerm_storage_account.default.primary_access_key} --share-name ${azurerm_storage_share.default-traefik.name} --source \"nodered.toml\" --path \"services\\nodered.toml\""
    }
}

# resource "local_file" "filebrowser-toml" {
#     content     = <<-EOT
#                   [http]
#                     # Add the router
#                     [http.routers]
#                       [http.routers.filebrowser]
#                         entrypoints = ["https"]
#                         service = "filebrowser"
#                         rule = "Host(`${join("", [var.tag_application_name[terraform.workspace], ".", var.location["DE"].regionCode ,".azurecontainer.io"])}`)"
#                       [http.routers.filebrowser.tls]
#                         certResolver = "le"
#                       # middleware to strip the prefix
#                       [http.middlewares]
#                         [http.middlewares.filebrowser-stripprefix.stripprefix]
#                           prefixes = ["/filebrowser"]
#                         [http.middlewares.filebrowser-auth.basicauth]
#                           users = ["${var.BASIC_AUTH_USER}"]
#                       # Define how to reach an existing service on our infrastructure
#                       [http.services]
#                         [http.services.filebrowser]
#                           [http.services.filebrowser.loadBalancer]
#                             [[http.services.filebrowser.loadBalancer.servers]]
#                               # As we are in the same container group, container can talk to each other through localhost or 127.0.0.1
#                               url = "http://127.0.0.1:2880"
#                   EOT
    
#     filename = "filebrowser.toml"

#     provisioner "local-exec" {
#       command = "az storage directory create --account-name ${azurerm_storage_account.default.name} --account-key ${azurerm_storage_account.default.primary_access_key} --share-name ${azurerm_storage_share.default-traefik.name} --name \"services\" --output none"
#     }

#     provisioner "local-exec" {
#       command = "az storage file upload --account-name ${azurerm_storage_account.default.name} --account-key ${azurerm_storage_account.default.primary_access_key} --share-name ${azurerm_storage_share.default-traefik.name} --source \"filebrowser.toml\" --path \"services\\filebrowser.toml\""
#     }
# }

#############################################################################
# Container Instance
#############################################################################

resource "azurerm_container_group" "default" {
  name                = join("-", [terraform.workspace, var.tag_application_name[terraform.workspace]])
  location            = "${azurerm_resource_group.default.location}"
  resource_group_name = "${azurerm_resource_group.default.name}"
  ip_address_type     = "Public"
  dns_name_label      = var.tag_application_name[terraform.workspace]
  os_type             = "Linux"

  ############################
  # Traefik
  ############################

  exposed_port {
    port     = 80
    protocol = "TCP"
  }

  exposed_port {
    port     = 443
    protocol = "TCP"
  }

  container {
    name     = "traefik"
    image    = var.traefik_image[terraform.workspace]
    cpu      = "0.5"
    memory   = "0.5"
    commands = ["sh","-c","touch acme.json && chmod 600 acme.json && traefik"]

    ports {
      port     = 80
      protocol = "TCP"
    }

    ports {
      port     = 443
      protocol = "TCP"
    }

    volume {
      name = "traefik-config"
      mount_path = "/etc/traefik"
      read_only  = true
      share_name = "${azurerm_storage_share.default-traefik.name}"

      storage_account_name = "${azurerm_storage_account.default.name}"
      storage_account_key  = "${azurerm_storage_account.default.primary_access_key}"
    }

  }

  ############################
  # Node-RED
  ############################

  container {
    name     = "nodered"
    image    = var.nodered_image[terraform.workspace]
    cpu      = "0.5"
    memory   = "0.5"
    
    ports {
      port     = 1880
      protocol = "TCP"
    }

    environment_variables = {
      "TZ" = "Europe/Zurich"
      "NODE_RED_ENABLE_PROJECTS" = "true"
    }

    volume {
      name = "nodered-data"
      mount_path = "/data"
      read_only  = false
      share_name = "${azurerm_storage_share.default-data.name}"

      storage_account_name = "${azurerm_storage_account.default.name}"
      storage_account_key  = "${azurerm_storage_account.default.primary_access_key}"
    }

    volume {
      name = "nodered-migration"
      mount_path = "/migration"
      read_only  = false
      share_name = "${azurerm_storage_share.default-migration.name}"

      storage_account_name = "${azurerm_storage_account.default.name}"
      storage_account_key  = "${azurerm_storage_account.default.primary_access_key}"
    }
  }

  # # ############################
  # # # Filebrowser
  # # ############################

  # # az container logs --resource-group TST-rg-aci-kstjj-004 --name TST-nodered-aci-tst --container-name filebrowser

  # container {
  #   name     = "filebrowser"
  #   image    = var.filebrowser_image[terraform.workspace]
  #   cpu      = "0.5"
  #   memory   = "0.5"
    
  #   ports {
  #     port     = 2880
  #     protocol = "TCP"
  #   }

  #   volume {
  #     name = "filebrowser-database"
  #     mount_path = "/database"
  #     read_only  = false
  #     share_name = "${azurerm_storage_share.default-migration.name}"

  #     storage_account_name = "${azurerm_storage_account.default.name}"
  #     storage_account_key  = "${azurerm_storage_account.default.primary_access_key}"
  #   }

  #   volume {
  #     name = "filebrowser-migration"
  #     mount_path = "/migration"
  #     read_only  = false
  #     share_name = "${azurerm_storage_share.default-migration.name}"

  #     storage_account_name = "${azurerm_storage_account.default.name}"
  #     storage_account_key  = "${azurerm_storage_account.default.primary_access_key}"
  #   }

  # }

}
