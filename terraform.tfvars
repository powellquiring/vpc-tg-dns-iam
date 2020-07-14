# sym link this files into each of the directories
ibm_region = "us-south"
generation = 2
#basename   = "project00"
#basename   = "project01"
#basename   = "project02"
basename   = "project03"
ibm_zones = [
  "us-south-1",
  "us-south-2",
  "us-south-3",
]
ssh_key_name = "pfq" # todo

centos_minimal = {
  "1" = "ibm-centos-7-6-minimal-amd64-1"
  "2" = "ibm-centos-7-6-minimal-amd64-2"
  # "2" = "ibm-centos-7-6-minimal-amd64-1"
}
ubuntu1804 = {
  "1" = "ubuntu-18.04-amd64"
  "2" = "ibm-ubuntu-18-04-64"
}
profile = {
  "1" = "cc1-2x4"
  "2" = "cx2-2x4"
}
shared_lb = false
