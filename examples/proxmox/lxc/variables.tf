variable "pm_api_base_url" {}
variable "pm_user" {}
variable "pm_password" {}
variable "pm_api_token_id" {}
variable "pm_api_token_secret" {}

variable "ct_target_node" {
  default     = "bkp"
  description = "The Proxmox node, where workloads will be placed."
}

variable "ct_ostemplate" {
  default = "local:vztmpl/debian-11-standard_11.6-1_amd64.tar.zst"
}

variable "ct_sshkey_1" {}

#############################################################################
# TAGS
#
# tag_environment = terraform.workspace
#
#############################################################################
variable "tag_owner" {
  default = "jan.jambor@xwr.ch"
}

# App name set in main.tf
# variable "tag_application_name" {
#   default     = "backup"
# }

variable "tag_costcenter" {
  default = "jj"
}

variable "tag_dr" {
  default = "essential"
}