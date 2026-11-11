#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install sms-gateway "$SANDBOX/sms-gateway" -n "$NS" --wait --timeout 90s >/dev/null
helm upgrade sms-gateway "$SANDBOX/sms-gateway" -n "$NS" --set carrier=contoso --wait --timeout 90s >/dev/null
# the "cleanup"
kubectl delete service sms-gateway -n "$NS" >/dev/null

hm_assert_status sms-gateway deployed
kubectl get service sms-gateway -n "$NS" >/dev/null 2>&1 && { echo "setup: service still exists"; exit 1; }
[ "$(hm_release_revision sms-gateway)" = "2" ] || { echo "setup: expected revision 2"; exit 1; }
