
#############################################################################
# Providers
#############################################################################

terraform {

  required_providers {

    proxmox = {
      source  = "telmate/proxmox"
      version = ">= 2.9.14"
    }

  }

}

#############################################################################
# LXC Container
#############################################################################

locals {
  ct_ipconfig_merged = merge(
    {
      name   = "eth0"
      bridge = "vmbr0"
      ip     = "dhcp"
      ip6    = "dhcp"
      gw     = ""
    },
    var.ct_ipconfig_override
  )
}

resource "proxmox_lxc" "basic" {
  target_node  = var.ct_target_node
  hostname     = join("", [var.tag_environment, var.tag_application_name])
  ostemplate   = var.ct_ostemplate
  unprivileged = var.ct_unprivileged
  onboot       = var.ct_onboot
  start        = true
  pool         = var.tag_environment

  cores  = var.ct_cpu
  memory = var.ct_memory_swap
  swap   = var.ct_memory_swap

  features {
    nesting = var.ct_features.nesting
  }

  #optional parameters to aviod recreating the container
  bwlimit              = 0
  force                = false
  ignore_unpack_errors = false
  restore              = false

  #password      = "Launch" # var.ct_password
  ssh_public_keys = <<-EOT
    ${var.ct_sshkey_1}
  EOT

  // Terraform will crash without rootfs defined
  rootfs {
    storage = "zfs"
    size    = "${var.ct_root_disk}G"
  }

  // Storage Backed Mount Point
  mountpoint {
    key     = "0"
    slot    = 0
    storage = "zfs"
    mp      = "/data"
    # when the value is 0 we must set the size to "0T" other wise we take the provided value in GB
    size = var.ct_disk == 0 ? "0T" : "${var.ct_disk}G"
  }

  network {
    name   = local.ct_ipconfig_merged.name
    bridge = local.ct_ipconfig_merged.bridge
    ip     = local.ct_ipconfig_merged.ip
    ip6    = local.ct_ipconfig_merged.ip6
    gw     = local.ct_ipconfig_merged.gw
  }

  # copy script to container
  provisioner "file" {
    source      = "install-scripts/${var.ct_initscript}"
    destination = "/tmp/${var.ct_initscript}"

    connection {
      type = "ssh"
      user = "root"
      host = proxmox_lxc.basic.hostname
    }

  }

  # execute script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/${var.ct_initscript}",
      "/tmp/${var.ct_initscript} ${var.ct_initparameters}",
      "rm /tmp/${var.ct_initscript}",
    ]

    connection {
      type = "ssh"
      user = "root"
      host = proxmox_lxc.basic.hostname
    }

  }

  # The description field is not supported by the proxmox provider and shows up as changed every time
  lifecycle {
    ignore_changes = [
      description,
    ]
  }

}
