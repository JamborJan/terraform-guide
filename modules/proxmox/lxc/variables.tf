#############################################################################
# GENERAL VARIABLES
#############################################################################

variable "ct_target_node" {}
variable "ct_unprivileged" { default = true }
variable "ct_ostemplate" {}
variable "ct_onboot" { default = false }
variable "ct_sshkey_1" {}
variable "ct_initscript" {}
variable "ct_initparameters" {}
variable "ct_cpu" {}
variable "ct_memory_swap" {}
variable "ct_root_disk" {
    default = 8
    description = "Root disk size in GB"
}
variable "ct_disk" {}
variable "tag_environment" {}
variable "tag_application_name" {}
variable "ct_features" {
  type = object({
    nesting = bool
  })
  default = {
    nesting = false
  }
}
variable "ct_ipconfig_override" {
  type = map(string)
  default = {}
}
