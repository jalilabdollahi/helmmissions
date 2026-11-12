#!/bin/bash
# Wrong fix: bind the ServiceAccount to cluster-admin with kubectl.
set -euo pipefail
source "$HM_LIB"

kubectl create clusterrolebinding helmissions-flag-sync-admin --clusterrole=cluster-admin --serviceaccount="$NS:flag-sync"
kubectl label clusterrolebinding helmissions-flag-sync-admin helmissions.io/cleanup=true
sleep 5
