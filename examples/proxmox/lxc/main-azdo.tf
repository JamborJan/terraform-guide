#############################################################################
# Azuer DevOps Build Agent Variables
#############################################################################
variable "azdo_agent_count" {
  default = 1
}
variable "azdo_ct_cpu" {
  default = 1
}
variable "azdo_ct_memory_swap" {
  default = 4096
}
variable "azdo_root_disk" {
  default = 16
}
variable "azdo_ct_disk" {
  default = 0
}
variable "azdo_pat" {}
variable "azdo_url" {
  default = "https://xwr.visualstudio.com/"
}
variable "azdo_pool" {
  default = "jjspool"
}
variable "azdo_agent_name_prefix" {
  default = "-build-" # DEV-BUILD-1, DEV-BUILD-2, PRD-BUILD-1 ... 
}
variable "azdo_agent_version" {
  default = "2.217.2"
}

#############################################################################
# LXC for Azure Build Agent
# terraform import module.lxc-azdoba.proxmox_lxc.basic bkp/lxc/102
#############################################################################

module "lxc-azdoba" {
  count  = var.azdo_agent_count
  source = "../../../modules/proxmox/lxc"

  tag_environment      = terraform.workspace
  tag_application_name = join("", [var.azdo_agent_name_prefix, count.index])

  ct_target_node    = var.ct_target_node
  ct_onboot         = true
  ct_unprivileged   = true
  ct_ostemplate     = var.ct_ostemplate
  ct_sshkey_1       = var.ct_sshkey_1
  ct_initscript     = "azure-build-agent.sh"
  ct_initparameters = "'${var.azdo_url}' '${var.azdo_pat}' '${var.azdo_pool}' '${terraform.workspace}${var.azdo_agent_name_prefix}${count.index}' '${var.azdo_agent_version}'"
  ct_cpu            = var.azdo_ct_cpu
  ct_memory_swap    = var.azdo_ct_memory_swap
  ct_root_disk      = var.azdo_root_disk
  ct_disk           = var.azdo_ct_disk

  ct_features = {
    nesting = true
  }

}
