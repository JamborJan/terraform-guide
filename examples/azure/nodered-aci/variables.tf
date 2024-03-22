#############################################################################
# GENERAL VARIABLES
#############################################################################

variable location {
  type    = map(object({
    regionName  = string
    regionCode   = string
  }))
  default = {
    EU = {
      regionName  = "West Europe"
      regionCode  = "westeurope"
    }
    CH = {
      regionName  = "Switzerland North"
      regionCode  = "switzerlandnorth"
    }
    DE = {
      regionName  = "Germany West Central"
      regionCode  = "germanywestcentral"
    }
  }
}

variable resource_group_name {
  type = string
  default = "rg-aci-kstjj-004"
}
locals {
  full_rg_name =  join("-", [terraform.workspace, var.resource_group_name])
}

#############################################################################
# Azure Container Instance VARIABLES
#############################################################################

variable storage_name {
  # only letters and numbers!
  type = map(string)
  default = {
    TST = "stacikstjj004tst"
    PRD = "stacikstjj004prd"
  }
}

variable storage_share_name {
  type = map(string)
  default = {
    TST = "shstacikstjj004tst"
    PRD = "shstacikstjj004prd"
  }
}

# source: https://hub.docker.com/r/nodered/node-red/tags?page=1&name=3.
variable nodered_image {
  type = map(string)
  default = {
    TST = "nodered/node-red:3.0.2"
    PRD = "nodered/node-red:3.0.2"
  }
}

# source: https://hub.docker.com/_/traefik/tags
variable traefik_image {
  type = map(string)
  default = {
    TST = "traefik:v2.9.8"
    PRD = "traefik:v2.9.8"
  }
}

# source: https://hub.docker.com/r/filebrowser/filebrowser/tags?page=1&name=amd
variable filebrowser_image {
  type = map(string)
  default = {
    TST = "filebrowser/filebrowser:v2.23.0-s6"
    PRD = "filebrowser/filebrowser:v2.23.0-s6"
  }
}

variable BASIC_AUTH_USER {}

#############################################################################
# TAGS
#
# tag_environment = terraform.workspace
#
#############################################################################
variable "tag_owner" {
  default     = "jan.jambor@xwr.ch"
}

variable tag_application_name {
  type = map(string)
  default = {
    TST = "nodered-aci-tst"
    PRD = "nodered-aci"
  }
}

variable "tag_costcenter" {
  default     = "jj"
}

variable "tag_dr" {
  default     = "essential"
}
