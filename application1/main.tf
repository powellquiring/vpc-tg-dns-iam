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

data ibm_resource_group "application" {
  name = "${var.basename}-application"
}

data ibm_is_ssh_key "ssh_key" {
  name = var.ssh_key_name
}

data ibm_is_image "image" {
  # name = var.ubuntu1804[var.generation]
  name = var.centos_minimal[var.generation]
}

module user_data_app {
  source = "../common/user_data_app"
  remote_ip = "shared.widgets.com"
}

locals {
  network_context = data.terraform_remote_state.network.outputs.app1
}

resource ibm_is_instance "vsiapp1" {
  name    = "${var.basename}-vsiapp1"
  vpc     = local.network_context.vpc.id
  resource_group = data.ibm_resource_group.application.id
  zone    = local.network_context.subnets["z1"].zone
  keys    = [data.ibm_is_ssh_key.ssh_key.id]
  image   = data.ibm_is_image.image.id
  profile = var.profile[var.generation]

  primary_network_interface {
    subnet = local.network_context.subnets["z1"].id
    security_groups = [
      #local.network_context.security_group_ssh.id, # add to ssh and debug
      #local.network_context.security_group_install_software.id, #centos nodejs is not available on an IBM mirror use outbound_all
      local.network_context.security_group_outbound_all.id, # centos nodejs is not available on an IBM mirror
      local.network_context.security_group_ibm_dns.id, # local dns
      local.network_context.security_group_data_inbound_insecure.id, # curl from my desktop
    ]
  }
  user_data = module.user_data_app.user_data_centos
}

resource ibm_is_floating_ip "vsiapp1" {
  resource_group = data.ibm_resource_group.application.id
  name   = "${var.basename}-vsiapp1"
  target = ibm_is_instance.vsiapp1.primary_network_interface[0].id
}

#-------------------------------------------------------------------
output ibm1_public_ip {
  value = ibm_is_floating_ip.vsiapp1.address
}

output ibm1_private_ip {
  value = ibm_is_instance.vsiapp1.primary_network_interface[0].primary_ipv4_address
}

output ibm1_curl {
  value = <<EOS

ssh root@${ibm_is_floating_ip.vsiapp1.address}
curl ${ibm_is_floating_ip.vsiapp1.address}:3000; # get hello world string
curl ${ibm_is_floating_ip.vsiapp1.address}:3000/info; # get the private IP address
curl ${ibm_is_floating_ip.vsiapp1.address}:3000/remote; # get the remote private IP address
EOS
}
