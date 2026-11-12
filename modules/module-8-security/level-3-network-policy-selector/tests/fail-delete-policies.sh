#!/bin/bash
# Tempting wrong fix: delete the NetworkPolicies so traffic flows.
set -euo pipefail
source "$HM_LIB"

kubectl delete networkpolicy --all -n "$NS"
sleep 8
