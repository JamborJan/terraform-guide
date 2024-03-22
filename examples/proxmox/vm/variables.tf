/*
 * The API requires credentials. Use an API key (c.f. username/password), by going to the
 * web UI 'Datacenter' -> 'Permissions' -> 'API Tokens' and create a new set of credentials.
 *
*/
variable "pm_api_url" {
  description = "The proxmox api endpoint"
}


variable "pm_user" {
  description = "A username for password based authentication of the Proxmox API"
  type        = string
  default     = "root@pam"
}

variable "pm_password" {
  description = "A password for password based authentication of the Proxmox API"
  type        = string
  sensitive   = true
  default     = ""
}

variable "vm_sshkey_1" {
  description = "SSH public key to be added to the VM"
}

variable "vm_target_node" {
  default     = "pve"
  description = "The Proxmox node, where workloads will be placed."
}

#############################################################################
# TAGS
#
# tag_environment = terraform.workspace
#
#############################################################################
variable "tag_owner" {
  default = "jan.jambor@xwr.ch"
}

# App name set in main.tf
# variable "tag_application_name" {
#   default     = "backup"
# }

variable "tag_costcenter" {
  default = "jj"
}

variable "tag_dr" {
  default = "essential"
}