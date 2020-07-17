# sym link this files into each of the directories

# ssh_key_name = "REPLACE_IN_terrform_tfvars" # must replace with an existing vpc ssh key name 
basename = "project10" # prefix name for most resources
ibm_region = "us-south"

shared_lb = true # true to inject a vpc load balancer over the shared app
