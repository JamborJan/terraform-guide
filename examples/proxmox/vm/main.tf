module "ignition-vm" {
  source              = "../../../modules/proxmox/vm"
  pm_api_url    = var.pm_api_url
  pm_user       = var.pm_user
  pm_password   = var.pm_password
  target_node   = var.vm_target_node
  template_name = "flatcar-linux"
  butane_conf   = "${path.module}/vm-configuration.bu.tftpl"
  name          = "flatcar-sample-container"
  vm_id         = 500
  networks      = [{ bridge = "vmbr0", tag = 109 }]
  tags          = ["sample", "flatcar"]
  vm_count      = 0
  vm_sshkey_1   = var.vm_sshkey_1
}
