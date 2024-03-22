#############################################################################
# LXC Guardian
#############################################################################
# Terraform lifecycle prevent destroy is not possible for modules
# To prevent accidental destruction of resource, we use this null_resource
# Add all lxc containers that should be protected from accidental destruction
# Source: https://github.com/hashicorp/terraform/issues/18367
resource "null_resource" "lxc_guardian" {
  triggers = {
    lxc_portainer_id = module.lxc-portainer.lxc_id
    lxc_ftp_id       = module.lxc-ftp[0].lxc_id
    lxc_traefik_id   = module.lxc-traefik.lxc_id
  }

  lifecycle {
    prevent_destroy = true
  }
}
