output shared {
  value = {
    vpc = module.vpc_shared.vpc
    subnets = module.vpc_shared.subnets
    security_group_ssh = module.sg_shared.security_group_ssh
    security_group_install_software = module.sg_shared.security_group_install_software
    security_group_data_inbound = module.sg_shared.security_group_data_inbound
    security_group_data_outbound = module.sg_shared.security_group_data_outbound
    security_group_ibm_dns = module.sg_shared.security_group_ibm_dns
    security_group_outbound_all = module.sg_shared.security_group_outbound_all
    dns = {
      guid = ibm_resource_instance.dns.guid
      zone_id     = ibm_dns_zone.shared.zone_id
    }
  }
}

output app1 {
  value = {
    vpc = module.vpc_app1.vpc
    subnets = module.vpc_app1.subnets
    security_group_ssh = module.sg_app1.security_group_ssh
    security_group_install_software = module.sg_app1.security_group_install_software
    security_group_data_inbound = module.sg_app1.security_group_data_inbound
    security_group_data_inbound_insecure = module.sg_app1.security_group_data_inbound_insecure
    security_group_data_outbound = module.sg_app1.security_group_data_outbound
    security_group_ibm_dns = module.sg_app1.security_group_ibm_dns
    security_group_outbound_all = module.sg_app1.security_group_outbound_all
  }
}
