#############################################################################
# Specific Variables
#############################################################################
variable "traefik_ct_cpu" {
  default = 1
}
variable "traefik_ct_memory_swap" {
  default = 512 # 7 day average was 107MB
}
variable "traefik_ct_disk" {
  default = 0
}

#############################################################################
# LXC Container
#############################################################################

module "lxc-traefik" {
  source = "../../../modules/proxmox/lxc"

  tag_environment      = "dev"
  tag_application_name = "-traefik"

  ct_target_node    = var.ct_target_node
  ct_onboot         = true
  ct_unprivileged   = true
  ct_ostemplate     = "local:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst"
  ct_sshkey_1       = var.ct_sshkey_1
  ct_initscript     = "traefik.privat.sh"
  ct_initparameters = ""
  ct_cpu            = var.traefik_ct_cpu
  ct_memory_swap    = var.traefik_ct_memory_swap
  ct_disk           = var.traefik_ct_disk
  ct_ipconfig_override = {
    ip = "192.168.100.7/24"
    gw = "192.168.100.1"
  }

}
