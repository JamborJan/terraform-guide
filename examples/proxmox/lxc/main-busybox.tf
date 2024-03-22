#############################################################################
# Azuer DevOps Build Agent Variables
#############################################################################
variable "bub_agent_count" {
  default = 1
}
variable "bub_ct_cpu" {
  default = 1
}
variable "bub_ct_memory_swap" {
  default = 1024
}
variable "bub_ct_disk" {
  default = 8
}

variable "bub_agent_name_prefix" {
  default = "-busybox-"
}

#############################################################################
# LXC for Azure Build Agent
# terraform import module.lxc-azdoba.proxmox_lxc.basic bkp/lxc/102
#############################################################################

module "lxc-busybox" {
  count  = var.bub_agent_count
  source = "../../../modules/proxmox/lxc"

  tag_environment      = terraform.workspace
  tag_application_name = join("", [var.bub_agent_name_prefix, count.index])

  ct_target_node    = var.ct_target_node
  ct_onboot         = true
  ct_unprivileged   = true
  ct_ostemplate     = var.ct_ostemplate
  ct_sshkey_1       = var.ct_sshkey_1
  ct_initscript     = "busybox.sh"
  ct_initparameters = "'${var.ct_sshkey_1}'"
  ct_cpu            = var.bub_ct_cpu
  ct_memory_swap    = var.bub_ct_memory_swap
  ct_disk           = var.bub_ct_disk

}
