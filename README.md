# VPCs with Transit Gateway and DNS Services
https://github.com/powellquiring/vpc-tg-dns-iam

This tutorial walks you through creating the account resource groups and IAM access groups to organize independent teams to develop applications within VPCs connected by Transit Gateways.  Some isolation between IP addresses will be provided by private DNS names

# IAM and Access Groups

Team structure
- Admin team can add members and assign resources for the other teams
- Network team can create the VPC, subnets, ACLs etc
- Shared team deploys VSIs and software on the VSIs and configures it's DNS names
- Application team deploys VSIs and software on the VSIs

The table below shows how the shared resource group is used to allow the network team to administer network resources and the shared team to administer instances



|Resource|Resource Group|Network|Shared|
-|-|-|-|
vpcId|shared|A|x
securityGroupId|shared|A|x
vpnGatewayId|shared|A|x
subnetId|shared|A|x
publicGatewayId|shared|A|x
flowLogCollectorId|shared|A|x
loadBalancerId|shared|A|x
networkAclId|shared|A|x
instanceId|shared|x|A
volumeId|shared|x|A
floatingIpId|shared|x|A
keyId|shared|x|A
imageId|shared|x|A
instanceGroupId|shared|x|A
dedicatedHostId|shared|x|A



# Admin

There are users listed in the admin/main.tf file.
Personal note: I used 
- pquiring+network@mail.test.us.ibm.com
- pquiring+application@mail.test.us.ibm.com
- pquiring+shared@mail.test.us.ibm.com

Terraform
- Resource Groups
- Access Groups
- Add Users

# Network
- Define network architecture including cidr blocks allocation
- Create network resources in the network resource group: vpc, address prefixes, subnets, resource groups, network acls
- Create the transit gateway:
  - application1 -> shared
  - application2 -> (application1, shared)
- Create DNS instance, create a zone, permit the zone on the vpcs

# Shared team
- Create DNS records

# Application and DNS

Terraform
- Import VPC, subnets, ACLs
- Create VSIs
- Publish DNS record in an existing zone

Deploy applications
- 

```
cat > /etc/dhcp/dhclient.conf <<EOF
supersede domain-name-servers 161.26.0.7, 161.26.0.8;
EOF
dhclient -v -r eth0; dhclient -v eth0
curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
yum install nodejs -y


yum install bind-utils -y
dig shared.widgets.com @161.26.0.7

```
