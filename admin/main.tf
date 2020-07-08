provider "ibm" {
  region           = var.ibm_region
  ibmcloud_api_key = var.ibmcloud_api_key # /DELETE_ON_PUBLISH/d
  generation       = var.generation
}

# ---------------- resource groups
resource "ibm_resource_group" "network" {
  name = "${var.basename}-network"
}
resource "ibm_resource_group" "shared" {
  name = "${var.basename}-shared"
}
resource "ibm_resource_group" "application" {
  name = "${var.basename}-application"
}

# ---------------- access groups and members
resource "ibm_iam_access_group" "network" {
  name        = "${var.basename}-network"
  description = "network administrators"
}

resource "ibm_iam_access_group_members" "network" {
  access_group_id = ibm_iam_access_group.network.id
  ibm_ids         = ["pquiring+network@mail.test.us.ibm.com"]
}

resource "ibm_iam_access_group" "shared" {
  name        = "${var.basename}-shared"
  description = "shared administrators"
}

resource "ibm_iam_access_group_members" "shared" {
  access_group_id = ibm_iam_access_group.shared.id
  ibm_ids         = ["pquiring+shared@mail.test.us.ibm.com"]
}

resource "ibm_iam_access_group" "application" {
  name        = "${var.basename}-application"
  description = "application administrators"
}

resource "ibm_iam_access_group_members" "application" {
  access_group_id = ibm_iam_access_group.application.id
  ibm_ids         = ["pquiring+application@mail.test.us.ibm.com"]
}

# ---------------- access to resource groups
resource "ibm_iam_access_group_policy" "network_policy" {
  access_group_id = ibm_iam_access_group.network.id
  roles           = ["Viewer"]
  resources {
    resource_type = "resource-group"
    resource      = ibm_resource_group.network.id
  }
}

resource "ibm_iam_access_group_policy" "networkshared_policy" {
  access_group_id = ibm_iam_access_group.network.id
  roles           = ["Viewer"]
  resources {
    resource_type = "resource-group"
    resource      = ibm_resource_group.shared.id
  }
}

resource "ibm_iam_access_group_policy" "networkappliation_policy" {
  access_group_id = ibm_iam_access_group.network.id
  roles           = ["Viewer"]
  resources {
    resource_type = "resource-group"
    resource      = ibm_resource_group.application.id
  }
}

resource "ibm_iam_access_group_policy" "shared_policy" {
  access_group_id = ibm_iam_access_group.shared.id
  roles           = ["Viewer"]
  resources {
    resource_type = "resource-group"
    resource      = ibm_resource_group.shared.id
  }
}

resource "ibm_iam_access_group_policy" "application_policy" {
  access_group_id = ibm_iam_access_group.application.id
  roles           = ["Viewer"]
  resources {
    resource_type = "resource-group"
    resource      = ibm_resource_group.application.id
  }
}



locals {
  network_attributes = {
    "vpnGatewayId"       = "*"
    "publicGatewayId"    = "*"
    "flowLogCollectorId" = "*"
    "loadBalancerId"     = "*"
    "networkAclId"       = "*"
  }
  network_app_attributes = { # operator access is required for these vpc resources by the software teams
    "vpcId"           = "*"
    "subnetId"        = "*"
    "securityGroupId" = "*"
  }
  app_attributes = { # app is both shared and application
    "instanceId"      = "*"
    "volumeId"        = "*"
    "floatingIpId"    = "*"
    "keyId"           = "*"
    "imageId"         = "*"
    "instanceGroupId" = "*"
    "dedicatedHostId" = "*"
  }
}

# ---------------- network team only
resource "ibm_iam_access_group_policy" "transit" {
  access_group_id = ibm_iam_access_group.network.id
  roles           = ["Administrator"]

  resources {
    service           = "transit"
    resource_group_id = ibm_resource_group.network.id
  }
}

# ---------------- shared and network resource group for the network team
resource "ibm_iam_access_group_policy" "networkshared_is_resources" {
  access_group_id = ibm_iam_access_group.network.id
  roles           = ["Editor"]

  for_each = merge(local.network_attributes, local.network_app_attributes)
  resources {
    service = "is"
    attributes = {
      "${each.key}" = each.value
    }
    resource_group_id = ibm_resource_group.shared.id
  }
}

resource "ibm_iam_access_group_policy" "networkapplication_is_resources" {
  access_group_id = ibm_iam_access_group.network.id
  roles           = ["Editor"]

  for_each = merge(local.network_attributes, local.network_app_attributes)
  resources {
    service = "is"
    attributes = {
      "${each.key}" = each.value
    }
    resource_group_id = ibm_resource_group.application.id
  }
}

# ---------------- shared resource group - shared team
resource "ibm_iam_access_group_policy" "shared_is_network_resources" {
  access_group_id = ibm_iam_access_group.shared.id
  roles           = ["Viewer"]

  for_each = local.network_attributes
  resources {
    service = "is"
    attributes = {
      "${each.key}" = each.value
    }
    resource_group_id = ibm_resource_group.shared.id
  }
}

resource "ibm_iam_access_group_policy" "shared_is_network_operator_resources" {
  access_group_id = ibm_iam_access_group.shared.id
  roles           = ["Operator"]

  for_each = local.network_app_attributes
  resources {
    service = "is"
    attributes = {
      "${each.key}" = each.value
    }
    resource_group_id = ibm_resource_group.shared.id
  }
}

resource "ibm_iam_access_group_policy" "shared_is_instance_resources" {
  access_group_id = ibm_iam_access_group.shared.id
  roles           = ["Administrator"]

  for_each = local.app_attributes
  resources {
    service = "is"
    attributes = {
      "${each.key}" = each.value
    }
    resource_group_id = ibm_resource_group.shared.id
  }
}


# ---------------- application resource group - application team
resource "ibm_iam_access_group_policy" "application_is_network_resources" {
  access_group_id = ibm_iam_access_group.application.id
  roles           = ["Viewer"]

  for_each = local.network_attributes
  resources {
    service = "is"
    attributes = {
      "${each.key}" = each.value
    }
    resource_group_id = ibm_resource_group.application.id
  }
}

resource "ibm_iam_access_group_policy" "application_is_network_operator_resources" {
  access_group_id = ibm_iam_access_group.application.id
  roles           = ["Operator"]

  for_each = local.network_app_attributes
  resources {
    service = "is"
    attributes = {
      "${each.key}" = each.value
    }
    resource_group_id = ibm_resource_group.application.id
  }
}

resource "ibm_iam_access_group_policy" "application_is_instance_resources" {
  access_group_id = ibm_iam_access_group.application.id
  roles           = ["Administrator"]

  for_each = local.app_attributes
  resources {
    service = "is"
    attributes = {
      "${each.key}" = each.value
    }
    resource_group_id = ibm_resource_group.application.id
  }
}

# ---------------- dns can be created by the network team but managed by the shared team
resource "ibm_iam_access_group_policy" "dns_network" {
  access_group_id = ibm_iam_access_group.network.id
  roles           = ["Administrator", "Manager"]

  resources {
    service           = "dns-svcs"
    resource_group_id = ibm_resource_group.shared.id
  }
}

resource "ibm_iam_access_group_policy" "dns-shared" {
  access_group_id = ibm_iam_access_group.shared.id
  roles           = ["Viewer", "Manager"]

  resources {
    service           = "dns-svcs"
    resource_group_id = ibm_resource_group.shared.id
  }
}

# -----------------------------------
# share pfq ssh key
resource "ibm_iam_access_group_policy" "shared_is_key_pfq" {
  access_group_id = ibm_iam_access_group.shared.id
  roles           = ["Operator"]

  resources {
    service = "is"
    attributes = {
      "keyId" = "r006-267ead51-fbd5-435c-a92b-c9cac0d217d6"
    }
    #resource_group_id = ibm_resource_group.shared.id
  }
}
resource "ibm_iam_access_group_policy" "application_is_key_pfq" {
  access_group_id = ibm_iam_access_group.application.id
  roles           = ["Operator"]

  resources {
    service = "is"
    attributes = {
      "keyId" = "r006-267ead51-fbd5-435c-a92b-c9cac0d217d6"
    }
    #resource_group_id = ibm_resource_group.application.id
  }
}
