#############################################################################
# GENERAL VARIABLES
#############################################################################

variable location {
  type    = string
  default = "Switzerland North"
}

variable resource_group_name {
  type = string
  default = "rg-aci-kstjj-003"
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
    TST = "stacikstjj003tst"
    PRD = "stacikstjj003prd"
  }
}

variable restic_image {
  type = map(string)
  default = {
    TST = "restic/restic:0.14.0"
    PRD = "restic/restic:0.14.0"
  }
}

variable RESTIC_REPOSITORY {
  type = map(string)
  default = {
    TST = "azure:backup:/"
    PRD = "azure:backup:/"
  }
}

#############################################################################
# Secrets
#############################################################################

variable RESTIC_PASSWORD {}

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
    TST = "restic-backup-tst"
    PRD = "restic-backup"
  }
}

variable "tag_costcenter" {
  default     = "jj"
}

variable "tag_dr" {
  default     = "essential"
}