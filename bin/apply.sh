#!/bin/bash
set -ex
for d in admin network shared application1; do
  (cd $d; source ./local.env; terraform apply -auto-approve)
done
