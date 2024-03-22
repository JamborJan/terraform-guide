#############################################################################
# Portainer Variables
#############################################################################
variable "port_ct_cpu" {
  default = 1
}
variable "port_ct_memory_swap" {
  default = 1024
}
variable "port_ct_disk" {
  default = 8
}

variable "portainer_agent_secret" {}

#############################################################################
# LXC Container for Portainer Server
#############################################################################

module "lxc-portainer" {
  source = "../../../modules/proxmox/lxc"

  tag_environment      = terraform.workspace
  tag_application_name = "-port-s"

  ct_target_node    = var.ct_target_node
  ct_onboot         = true
  ct_unprivileged   = true
  ct_ostemplate     = var.ct_ostemplate
  ct_sshkey_1       = var.ct_sshkey_1
  ct_initscript     = "portainer.sh"
  ct_initparameters = ""
  ct_cpu            = var.port_ct_cpu
  ct_memory_swap    = var.port_ct_memory_swap
  ct_disk           = var.port_ct_disk
  ct_features = {
    nesting = true
  }

}
