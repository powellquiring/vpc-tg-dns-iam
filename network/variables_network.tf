variable tgw_region {
  default = "us-south"
}

variable network_architecture {
  default = {
    shared = {
      region      = "us-south"
      cidr        = "10.0.0.0/16"
      cidr_remote = "10.0.0.0/8"
      zones = {
        z1 = {
          name = "us-south-1",
          cidr = "10.0.0.0/24",
        }
        z2 = {
          name = "us-south-1",
          cidr = "10.0.1.0/24",
        }
        z3 = {
          name = "us-south-1",
          cidr = "10.0.2.0/24",
        }
      }
    }
    application1 = {
      region = "us-south"
      cidr   = "10.1.0.0/16"
      cidr_remote = "0.0.0.0"
      zones = {
        z1 = {
          name = "us-south-1",
          cidr = "10.1.0.0/24",
        }
        z2 = {
          name = "us-south-1",
          cidr = "10.1.1.0/24",
        }
        z3 = {
          name = "us-south-1",
          cidr = "10.1.2.0/24",
        }
      }
    }
    application2 = {
      region = "us-south"
      cidr   = "10.2.0.0/16"
      zones = {
        z1 = {
          name = "us-south-1",
          cidr = "10.2.0.0/24",
        }
        z2 = {
          name = "us-south-1",
          cidr = "10.2.1.0/24",
        }
        z3 = {
          name = "us-south-1",
          cidr = "10.2.2.0/24",
        }
      }
    }
  }
}
