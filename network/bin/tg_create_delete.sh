#!/bin/bash
set -e -o pipefail
echo TG_NAME $TG_NAME
echo TG_LOCATION $TG_LOCATION
echo TG_RESOURCE_GROUP_ID $TG_RESOURCE_GROUP_ID
echo TG_VPC_CRNS $TG_VPC_CRNS
echo TG_GLOBAL $TG_GLOBAL

# globals containing json returned from the tg commands
GATEWAYS=""
CONNECTIONS=""
GATEWAY_ID=""

# tg_* are ibmcloud tg * commands
tg_gateways() {
  GATEWAYS=$(ibmcloud tg gateways --output json | sed '/^OK/d')
}
tg_gateway_create() {
  ibmcloud tg gateway-create --routing $TG_GLOBAL --location $TG_LOCATION --name $TG_NAME --resource-group-id $TG_RESOURCE_GROUP_ID
}
tg_gateway_delete() {
  ibmcloud tg gateway-delete $GATEWAY_ID --force
}
tg_connection_create() {
  local vpc_crn=$1
  local name=$(echo "$vpc_crn" | cut -c 75-)
  ibmcloud tg connection-create $GATEWAY_ID --name $name --network-type vpc --network-id $vpc_crn
}
tg_connections() {
  CONNECTIONS=$(ibmcloud tg connections $GATEWAY_ID --output json | sed '/^OK/d')
}
tg_connection_delete() {
  local vpc_crn=$1
  local connection_id=$(echo "$CONNECTIONS" | jq -r '.[] | select(.network_id=="'$vpc_crn'") | .id')
  ibmcloud tg connection-delete $GATEWAY_ID $connection_id --force
}
set_gateway_id() {
  GATEWAY_ID=$(echo "$GATEWAYS" | jq -r '.[] | select(.name=="'$TG_NAME'") | .id')
}

# exists and status commands
gateway_exists() {
  echo "$GATEWAYS" | jq -e '.[] | select(.name=="'$TG_NAME'")' > /dev/null
}
gateway_status_available() {
  echo "$GATEWAYS" | jq -e '.[] | select(.name=="'$TG_NAME'" and .status=="'available'")' > /dev/null
}
connection_exists() {
  local vpc_crn=$1
  echo "$CONNECTIONS" | jq -e '.[] | select(.network_id=="'$vpc_crn'")' > /dev/null
}
connection_status_attached() {
  local vpc_crn=$1
  echo "$CONNECTIONS" | jq -e '.[] | select(.network_id=="'$vpc_crn'" and .status=="'attached'")' > /dev/null
}

# Creates connections if needed returns true when done.
# Caller should call until true
connections_attached() {
  tg_connections
  for vpc_crn in $TG_VPC_CRNS; do
    if ! connection_exists $vpc_crn; then
      tg_connection_create $vpc_crn
      return 1
    fi
    # connection exists, is it attached
    if ! connection_status_attached $vpc_crn; then
      return 1
    fi
  done
  return 0
}

connections_exist() {
  tg_connections
  for vpc_crn in $TG_VPC_CRNS; do
    if connection_exists $vpc_crn; then
      return 0
    fi
  done
  return 1
}

delete_connections() {
  tg_connections
  for vpc_crn in $TG_VPC_CRNS; do
    if connection_exists $vpc_crn; then
      tg_connection_delete $vpc_crn
    fi
  done
}

tgcreate() {
  tg_gateways
  if ! gateway_exists; then
    tg_gateway_create
  fi
  while true; do
    set_gateway_id
    if ! gateway_status_available; then
      tg_gateways
      sleep 2
      continue
    fi
    # gateway exists and is available
    if connections_attached; then
      break
    fi
    sleep 2
  done
}

tgdelete() {
  tg_gateways
  if ! gateway_exists; then
    exit 0
  fi
  set_gateway_id
  delete_connections
  while true; do
    if ! connections_exist; then
      break
    fi
    sleep 2
  done
  tg_gateway_delete
  while true; do
    tg_gateways
    if ! gateway_exists; then
      break
    fi
    sleep 2
  done
}

if [ $1 = create ]; then
  tgcreate
else
  tgdelete
fi
