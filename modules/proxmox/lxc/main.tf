
#############################################################################
# Providers
#############################################################################

terraform {

  required_providers {

    proxmox = {
      source  = "telmate/proxmox"
      version = ">= 2.9.11"
    }

  }
  
}

#############################################################################
# LXC Container
#############################################################################

resource "proxmox_lxc" "basic" {
  target_node   = var.ct_target_node
  hostname      = join("-", [terraform.workspace, var.tag_application_name])
  ostemplate    = var.ct_ostemplate
  unprivileged  = true
  onboot        = false
  start         = true
  pool          = var.tag_environment

  cores         = var.ct_cpu
  memory        = var.ct_memory_swap
  swap          = var.ct_memory_swap

  #password      = "Launch" # var.ct_password
  ssh_public_keys = <<-EOT
    ${var.ct_sshkey_1}
  EOT

  // Terraform will crash without rootfs defined
  rootfs {
    storage = "zfs"
    size    = "8G"
  }

  // Storage Backed Mount Point
  mountpoint {
    key     = "0"
    slot    = 0
    storage = "zfs"
    mp      = "/data"
    size    = "${var.ct_disk}G"
  }

  network {
    name    = "eth0"
    bridge  = "vmbr0"
    ip      = "${var.ct_ipaddress}/24"
    gw      = var.ct_ipgateway
    ip6     = "auto"
  }
  
  # copy script to container
  provisioner "file" {
    source      = "install-scripts/${var.ct_initscript}"
    destination = "/tmp/${var.ct_initscript}"

    connection {
      type     = "ssh"
      user     = "root"
      #password = var.ct_password #login via ssh key only
      host     = var.ct_ipaddress
    }

  }

  # execute script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/${var.ct_initscript}",
      "/tmp/${var.ct_initscript}",
      "rm /tmp/${var.ct_initscript}",
    ]
  
    connection {
      type     = "ssh"
      user     = "root"
      #password = var.ct_password #login via ssh key only
      host     = var.ct_ipaddress
    }
  }

}
