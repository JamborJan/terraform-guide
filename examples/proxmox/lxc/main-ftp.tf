#############################################################################
# Variables
#############################################################################
variable "ftp_agent_count" {
  default     = 1
  description = "Number of FTP Agents to deploy"
}
variable "ftp_ct_cpu" {
  default     = 4
  description = "Number of CPU cores to allocate to the FTP Agent"
}
variable "ftp_ct_memory_swap" {
  default     = 16384
  description = "Amount of memory to allocate to the FTP Agent"
}
variable "ftp_ct_disk" {
  default     = 512
  description = "Amount of disk in GB space to allocate to the FTP Agent"
}

variable "ftp_agent_name_prefix" {
  default     = "-ftp-"
  description = "Prefix for the FTP Agent name"
}

variable "ftp_user_password" {
  description = "Password for the FTP user"
}

#############################################################################
# LXC Container
#############################################################################

module "lxc-ftp" {
  count  = var.ftp_agent_count
  source = "../../../modules/proxmox/lxc"

  tag_environment      = "prd"
  tag_application_name = join("", [var.ftp_agent_name_prefix, count.index])

  ct_target_node    = var.ct_target_node
  ct_onboot         = true
  ct_unprivileged   = true
  ct_ostemplate     = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst" # var.ct_ostemplate
  ct_sshkey_1       = var.ct_sshkey_1
  ct_initscript     = "ftp.sh"
  ct_initparameters = "'${var.ftp_user_password}'"
  ct_cpu            = var.ftp_ct_cpu
  ct_memory_swap    = var.ftp_ct_memory_swap
  ct_disk           = var.ftp_ct_disk

}
