# VPCs with Transit Gateway and DNS Services
https://github.com/powellquiring/vpc-tg-dns-iam

This tutorial walks you through creating the account resource groups and IAM access groups to organize independent teams to develop applications within VPCs connected by Transit Gateways.  Some isolation between IP addresses will be provided by private DNS names

# IAM and Access Groups

Team structure
- Admin team can add members and assign resources for the other teams
- Network team can create the VPC, subnets, ACLs etc
- Shared team deploys VSIs and software on the VSIs and configures it's DNS names
- Application team deploys VSIs and software on the VSIs

The admin team creates an IAM policy group for each team.  The policies for the VPC Infrastructure can be grouped:

Instance
- instanceId
- volumeId
- floatingIpId
- keyId
- imageId
- instanceGroupId
- dedicatedHostId
- loadBalancerId

InstanceConnectivity
- vpcId
- subnetId
- securityGroupId

PureNetwork:
- vpnGatewayId
- publicGatewayId
- flowLogCollectorId
- networkAclId

Instance resources are administered by the shared and application team. InstanceConnectivity are administered (created/destroyed) by the network team and operated by the application team.  Operator access for a subnet is required to create an instance on the subnet.  PureNetwork is administered by the network team.  The shared team has the same permissions as the application team.

Infrastructure (VPC) simplified graphic representation.  Teams are in boxes and resources are in double boxes:

``` mermaid
graph TD;
  Shared --Editor--> Instance[[Instance]]
  Shared --Operator--> InstanceConnectivity[[InstanceConnectivity]]
  Network --Editor--> InstanceConnectivity;
  Network --Editor--> PureNetwork[[PureNetwork]];
```

The Transit Gateway service is administered by the Network team.  Same with the DNS service

``` mermaid
graph TD;
  Network --Editor--> dns-transit[[Transit Gateway]]
  Network --Editor/Manager--> dns-svcs[[DNS]]
  Shared --Manager--> dns-svcs[[DNS]]
```

The policy group details are captured in the tables below. 
- role-X platform role X for a specific service and resource type within the service
- serviceRole-X role X for a service

Policy Group project00-network:
roles|resource group|access
-|-|-
role-Editor,serviceRole-Manager|project00-shared|sn-dns-svcs
role-Editor|project00-application|sn-is,flowLogCollectorId
role-Editor|project00-application|sn-is,networkAclId
role-Editor|project00-application|sn-is,publicGatewayId
role-Editor|project00-application|sn-is,securityGroupId
role-Editor|project00-application|sn-is,subnetId
role-Editor|project00-application|sn-is,vpcId
role-Editor|project00-application|sn-is,vpnGatewayId
role-Editor|project00-network|sn-transit
role-Editor|project00-shared|sn-is,flowLogCollectorId
role-Editor|project00-shared|sn-is,networkAclId
role-Editor|project00-shared|sn-is,publicGatewayId
role-Editor|project00-shared|sn-is,securityGroupId
role-Editor|project00-shared|sn-is,subnetId
role-Editor|project00-shared|sn-is,vpcId
role-Editor|project00-shared|sn-is,vpnGatewayId
role-Viewer||rt-resource-group,rg-project00-application
role-Viewer||rt-resource-group,rg-project00-network
role-Viewer||rt-resource-group,rg-project00-shared

Policy Group project00-shared:
roles|resource group|access
-|-|-
role-Editor|project00-shared|sn-is,dedicatedHostId
role-Editor|project00-shared|sn-is,floatingIpId
role-Editor|project00-shared|sn-is,imageId
role-Editor|project00-shared|sn-is,instanceGroupId
role-Editor|project00-shared|sn-is,instanceId
role-Editor|project00-shared|sn-is,keyId
role-Editor|project00-shared|sn-is,loadBalancerId
role-Editor|project00-shared|sn-is,volumeId
role-Operator|project00-shared|sn-is,securityGroupId
role-Operator|project00-shared|sn-is,subnetId
role-Operator|project00-shared|sn-is,vpcId
role-Operator||sn-is,keyId-pfq
role-Viewer,serviceRole-Manager|project00-shared|sn-dns-svcs
role-Viewer||rt-resource-group,rg-project00-shared

Policy Group project00-application:
roles|resource group|access
-|-|-
role-Editor|project00-application|sn-is,dedicatedHostId
role-Editor|project00-application|sn-is,floatingIpId
role-Editor|project00-application|sn-is,imageId
role-Editor|project00-application|sn-is,instanceGroupId
role-Editor|project00-application|sn-is,instanceId
role-Editor|project00-application|sn-is,keyId
role-Editor|project00-application|sn-is,loadBalancerId
role-Editor|project00-application|sn-is,volumeId
role-Operator|project00-application|sn-is,securityGroupId
role-Operator|project00-application|sn-is,subnetId
role-Operator|project00-application|sn-is,vpcId
role-Operator||sn-is,keyId-pfq
role-Viewer||rt-resource-group,rg-project00-application

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
