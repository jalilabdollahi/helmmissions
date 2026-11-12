#!/bin/bash
# Partial fix: update the CRD but never redeploy - release stays failed and the policy lacks the field.
set -euo pipefail
source "$HM_LIB"

kubectl apply -f snapshot-scheduler/crds/
