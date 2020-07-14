provider ibm {
  region           = var.ibm_region
  ibmcloud_api_key = var.ibmcloud_api_key # /DELETE_ON_PUBLISH/d
  generation       = var.generation
}

data terraform_remote_state "network" {
  backend = "local"
  config = {
    path = "${path.module}/../network/terraform.tfstate"
  }
}

data ibm_resource_group "shared" {
  name = "${var.basename}-shared"
}

data ibm_is_ssh_key "ssh_key" {
  name = var.ssh_key_name
}

data ibm_is_image "image" {
  # name = var.ubuntu1804[var.generation]
  name = var.centos_minimal[var.generation]
}

module user_data_app {
  source    = "../common/user_data_app"
  remote_ip = "REMOTE_IP" # no remote ip
}

locals {
  network_context = data.terraform_remote_state.network.outputs.shared
}

resource ibm_is_instance "vsishared" {
  name           = "${var.basename}-shared-vsi"
  vpc            = local.network_context.vpc.id
  resource_group = data.ibm_resource_group.shared.id
  zone           = local.network_context.subnets["z1"].zone
  keys           = [data.ibm_is_ssh_key.ssh_key.id]
  image          = data.ibm_is_image.image.id
  profile        = var.profile[var.generation]

  primary_network_interface {
    subnet = local.network_context.subnets["z1"].id
    security_groups = [
      #local.network_context.security_group_install_software.id, # nodejs is not available on an IBM mirror
      local.network_context.security_group_outbound_all.id, # nodejs is not available on an IBM mirror
      #local.network_context.security_group_ssh.id, # TODO not needed
      local.network_context.security_group_ibm_dns.id,
      local.network_context.security_group_data_inbound.id,
    ]
  }
  user_data = module.user_data_app.user_data_centos
}

resource ibm_is_floating_ip "vsishared" {
  resource_group = data.ibm_resource_group.shared.id
  name           = "${var.basename}-vsishared"
  target         = ibm_is_instance.vsishared.primary_network_interface[0].id
}

#-------------------------------------------------------------------
# shared.widgets.com
resource ibm_dns_resource_record "shared" {
  count = var.shared_lb ? 0 : 1 # shared load balancer?
  instance_id = local.network_context.dns.guid
  zone_id     = local.network_context.dns.zone_id
  type        = "A"
  name        = "shared"
  rdata       = ibm_is_instance.vsishared.primary_network_interface[0].primary_ipv4_address
  ttl         = 3600
}

#-------------------------------------------------------------------
output ibm1_public_ip {
  value = ibm_is_floating_ip.vsishared.address
}

output ibm1_private_ip {
  value = ibm_is_instance.vsishared.primary_network_interface[0].primary_ipv4_address
}

output ibm1_curl {
  value = <<EOS

ssh root@${ibm_is_floating_ip.vsishared.address}
curl ${ibm_is_floating_ip.vsishared.address}:3000; # get hello world string
curl ${ibm_is_floating_ip.vsishared.address}:3000/info; # get the private IP address
EOS
  # curl ${ibm_is_floating_ip.vsishared.address}:3000/remote; # get the remote private IP address
}
