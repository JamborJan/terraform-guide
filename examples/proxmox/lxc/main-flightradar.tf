#############################################################################
# Flightradar Feeder Variables
#############################################################################
variable "flrd_count" {
  default = 1
}
variable "flrd_ct_cpu" {
  default = 1
}
variable "flrd_ct_memory_swap" {
  default = 1024
}
variable "flrd_ct_disk" {
  default = 8
}

#############################################################################
# LXC Container for Flightradar Feeder
#############################################################################

module "lxc-flightradar24" {
  count  = var.flrd_count
  source = "../../../modules/proxmox/lxc"

  tag_environment      = terraform.workspace
  tag_application_name = join("", ["-flrd-", count.index])

  ct_target_node    = var.ct_target_node
  ct_onboot         = true
  ct_unprivileged   = true
  ct_ostemplate     = var.ct_ostemplate
  ct_sshkey_1       = var.ct_sshkey_1
  ct_initscript     = "flightradar.sh"
  ct_initparameters = ""
  ct_cpu            = var.flrd_ct_cpu
  ct_memory_swap    = var.flrd_ct_memory_swap
  ct_disk           = var.flrd_ct_disk
  ct_features = {
    nesting = false
  }
}
