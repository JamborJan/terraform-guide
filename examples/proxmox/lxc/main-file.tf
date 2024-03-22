#############################################################################
# Variables
#############################################################################
variable "file_agent_count" {
  default     = 1
  description = "Number of LXC to deploy"
}
variable "file_ct_cpu" {
  default     = 1
  description = "Number of CPU cores to allocate to the LXC"
}
variable "file_ct_memory_swap" {
  default     = 2048
  description = "Amount of memory to allocate to the LXC"
}
variable "file_ct_disk" {
  default     = 10
  description = "Amount of disk in GB space to allocate to the LXC"
}

variable "file_agent_name_prefix" {
  default     = "-file-"
  description = "Prefix for the LXC name"
}

#############################################################################
# LXC Container
#############################################################################

# module "lxc-file" {
#   count  = var.file_agent_count
#   source = "../../../modules/proxmox/lxc"

#   tag_environment      = "dev"
#   tag_application_name = join("", [var.file_agent_name_prefix, count.index])

#   ct_target_node    = var.ct_target_node
#   ct_onboot         = true
#   ct_unprivileged   = true
#   ct_ostemplate     = "local:vztmpl/debian-11-standard_11.6-1_amd64.tar.zst"
#   #ct_ostemplate     = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
#   ct_sshkey_1       = var.ct_sshkey_1
#   ct_initscript     = "file.sh"
#   ct_initparameters = ""
#   ct_cpu            = var.file_ct_cpu
#   ct_memory_swap    = var.file_ct_memory_swap
#   ct_disk           = var.file_ct_disk

# }
