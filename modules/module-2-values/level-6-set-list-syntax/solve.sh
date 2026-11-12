#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install mesh-client ./mesh-client -n "$NS" \
  --set 'dnsSearch={payments.svc.cluster.local,corp.internal}' --wait --timeout 120s
