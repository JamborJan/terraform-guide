#############################################################################
# Specific Variables
#############################################################################
variable "plex_ct_cpu" {
  default = 2
}
variable "plex_ct_memory_swap" {
  default = 8192
}
variable "plex_ct_disk" {
  default = 16
}

#############################################################################
# LXC Container
#############################################################################

module "lxc-plex" {
  source = "../../../modules/proxmox/lxc"

  tag_environment      = terraform.workspace
  tag_application_name = "-plex-t"

  ct_target_node    = var.ct_target_node
  ct_onboot         = false
  ct_unprivileged   = true
  ct_ostemplate     = "local:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst"
  ct_sshkey_1       = var.ct_sshkey_1
  ct_initscript     = "plex.privat.sh"
  ct_initparameters = ""
  ct_cpu            = var.plex_ct_cpu
  ct_memory_swap    = var.plex_ct_memory_swap
  ct_disk           = var.plex_ct_disk

}
