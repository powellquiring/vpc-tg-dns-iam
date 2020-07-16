#!/bin/bash
set -ex

# admin  team
(
  cd admin
  [ -e local.env ] || echo export TF_VAR_ibmcloud_api_key=$(ibmcloud iam api-key-create project10-admin --output json | jq .apikey) > local.env
  source local.env
  terraform init
  terraform apply -auto-approve
)
basename=$(cd admin; terraform output basename)

# rest of the teams
for team in admin network shared application1; do
  (
    cd $team
    [ -e local.env ] || echo export TF_VAR_ibmcloud_api_key=$(ibmcloud iam service-api-key-create $team $basename-$team --output json | jq .apikey) > local.env
    source ./local.env
    terraform init
    terraform apply -auto-approve
  )
done
