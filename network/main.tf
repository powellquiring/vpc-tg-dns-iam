provider "ibm" {
  region           = var.ibm_region
  ibmcloud_api_key = var.ibmcloud_api_key # /DELETE_ON_PUBLISH/d
  generation       = var.generation
}

data "ibm_resource_group" "network" {
  name = "${var.basename}-network"
}

data "ibm_resource_group" "shared" {
  name = "${var.basename}-shared"
}
data "ibm_resource_group" "application1" {
  name = "${var.basename}-application1"
}
data "ibm_resource_group" "application2" {
  name = "${var.basename}-application2"
}

#-------------------------------------------------------------------
module "vpc_shared" {
  source            = "./vpc"
  region            = var.ibm_region
  vpc_architecture  = var.network_architecture.shared
  basename          = "${var.basename}-shared"
  resource_group_id = data.ibm_resource_group.shared.id
}
module "sg_shared" {
  source         = "./sg"
  basename       = "${var.basename}-sg-shared"
  vpc            = module.vpc_shared.vpc
  resource_group = data.ibm_resource_group.shared
  cidr_remote    = var.network_architecture.shared.cidr_remote
}

module "vpc_app1" {
  source            = "./vpc"
  region            = var.ibm_region
  vpc_architecture  = var.network_architecture.application1
  basename          = "${var.basename}-app1"
  resource_group_id = data.ibm_resource_group.application1.id
}
module "sg_app1" {
  source         = "./sg"
  basename       = "${var.basename}-sg-app1"
  vpc            = module.vpc_app1.vpc
  resource_group = data.ibm_resource_group.application1
  cidr_remote    = var.network_architecture.application1.cidr_remote
}

module "vpc_app2" {
  source            = "./vpc"
  region            = var.ibm_region
  vpc_architecture  = var.network_architecture.application2
  basename          = "${var.basename}-app2"
  resource_group_id = data.ibm_resource_group.application2.id
}
module "sg_app2" {
  source         = "./sg"
  basename       = "${var.basename}-sg-app2"
  vpc            = module.vpc_app2.vpc
  resource_group = data.ibm_resource_group.application2
  cidr_remote    = var.network_architecture.application2.cidr_remote
}

#-------------------------------------------------------------------
resource "ibm_resource_instance" "dns" {
  name              = "${var.basename}-dns"
  resource_group_id = data.ibm_resource_group.shared.id
  location          = "global"
  service           = "dns-svcs"
  plan              = "standard-dns"
}

resource "ibm_dns_zone" "widgets_com" {
  name        = "widgets.com"
  instance_id = ibm_resource_instance.dns.guid
  description = "this is a description"
  label       = "this-is-a-label"
}

resource "ibm_dns_permitted_network" "shared" {
  instance_id = ibm_resource_instance.dns.guid
  zone_id     = ibm_dns_zone.widgets_com.zone_id
  vpc_crn     = module.vpc_shared.vpc.crn
  type        = "vpc"
}

resource "ibm_dns_permitted_network" "app1" {
  depends_on  = [ibm_dns_permitted_network.shared]
  instance_id = ibm_resource_instance.dns.guid
  zone_id     = ibm_dns_zone.widgets_com.zone_id
  vpc_crn     = module.vpc_app1.vpc.crn
  type        = "vpc"
}

resource "ibm_dns_permitted_network" "app2" {
  depends_on  = [ibm_dns_permitted_network.app1]
  instance_id = ibm_resource_instance.dns.guid
  zone_id     = ibm_dns_zone.widgets_com.zone_id
  vpc_crn     = module.vpc_app2.vpc.crn
  type        = "vpc"
}

#-----------------------------------------------------
resource "null_resource" "transit_gateway" {
  triggers = {
    path_module       = path.module
    name              = "${var.basename}-tgw"
    location          = var.ibm_region
    resource_group_id = data.ibm_resource_group.network.id
    vpc_shared_crn    = module.vpc_shared.vpc.crn
    vpc_app1_crn      = module.vpc_app1.vpc.crn
    vpc_app2_crn      = module.vpc_app2.vpc.crn
  }
  provisioner "local-exec" {
    command = <<-EOS
      TG_NAME=${self.triggers.name} \
      TG_LOCATION=${self.triggers.location} \
      TG_RESOURCE_GROUP_ID=${self.triggers.resource_group_id} \
      TG_GLOBAL=local \
      TG_VPC_CRNS="${self.triggers.vpc_shared_crn} ${self.triggers.vpc_app1_crn} ${self.triggers.vpc_app2_crn}" \
      ${self.triggers.path_module}/bin/tg_create_delete.sh create
    EOS
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOS
      TG_NAME=${self.triggers.name} \
      TG_LOCATION=${self.triggers.location} \
      TG_RESOURCE_GROUP_ID=${self.triggers.resource_group_id} \
      TG_GLOBAL=local \
      TG_VPC_CRNS="${self.triggers.vpc_shared_crn} ${self.triggers.vpc_app1_crn} ${self.triggers.vpc_app2_crn}" \
      ${self.triggers.path_module}/bin/tg_create_delete.sh delete
    EOS
  }
}
