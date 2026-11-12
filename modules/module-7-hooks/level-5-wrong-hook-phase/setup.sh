#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install shipments "$LEVEL_DIR/assets/v1/shipment-tracker" -n "$NS" --wait --timeout 90s >/dev/null
hm_assert_status shipments deployed

# The CI deploy of 1.1: the new pods wait for a schema that only a post-upgrade hook would create.
helm upgrade shipments "$SANDBOX/shipment-tracker" -n "$NS" --wait --timeout 45s >"$HM_TMP/up.txt" 2>&1 && { echo "setup: upgrade succeeded — scenario not broken"; exit 1; }
hm_assert_status shipments failed
[ -z "$(kubectl get job shipments-migrate-v2 -n "$NS" -o name 2>/dev/null)" ] || { echo "setup: the migration hook ran"; exit 1; }
kubectl get pods -n "$NS" -o json | jq -e '[.items[] | select(.status.initContainerStatuses[]?.name=="wait-for-schema")] | length > 0' >/dev/null || { echo "setup: no pod stuck in the init container"; exit 1; }
