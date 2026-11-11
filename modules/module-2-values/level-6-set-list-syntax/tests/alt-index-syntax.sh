#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install mesh-client ./mesh-client -n "$NS" \
  --set 'dnsSearch[0]=payments.svc.cluster.local' --set 'dnsSearch[1]=corp.internal' --wait --timeout 120s
