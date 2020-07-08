#!/bin/bash
set -ex
for d in application1 shared network admin; do
  (cd $d; source ./local.env; terraform destroy -auto-approve)
done
