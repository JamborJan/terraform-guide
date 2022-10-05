#############################################################################
# GENERAL VARIABLES
#############################################################################

variable "ct_ostemplate" {
  default = "local:vztmpl/debian-11-standard_11.3-1_amd64.tar.zst"
}
variable "ct_sshkey_1" {}
variable "ct_ipgateway" {
  default = "192.168.100.1"
}

#############################################################################
# TAGS
#
# tag_environment = terraform.workspace
#
#############################################################################
variable "tag_owner" {
  default     = "jan.jambor@xwr.ch"
}

# App name set in main.tf
# variable "tag_application_name" {
#   default     = "backup"
# }

variable "tag_costcenter" {
  default     = "jj"
}

variable "tag_dr" {
  default     = "essential"
}