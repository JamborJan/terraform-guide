#############################################################################
# VM: flatcar linux for k8s
#############################################################################

module "lxc" {
  source = "../../../modules/proxmox/vm-flatcar"

  tag_application_name  = "azure-build-agent"
  tag_environment       = terraform.workspace

  # ct_target_node        = "bkp"
  # ct_ostemplate         = var.ct_ostemplate
  # ct_sshkey_1           = var.ct_sshkey_1
  # ct_ipaddress          = "192.168.100.13"
  # ct_ipgateway          = var.ct_ipgateway
  # ct_initscript         = "azure-build-agent.sh"
  # ct_cpu                = 1
  # ct_memory_swap        = 512
  # ct_disk               = 8
  
}
