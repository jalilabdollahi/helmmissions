#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install orders "$SANDBOX/order-service" -n "$NS" --timeout 90s >"$HM_TMP/install.txt" 2>&1 && { echo "setup: install succeeded — scenario not broken"; exit 1; }
hm_assert_status orders failed
kubectl logs job/orders-db-migrate -n "$NS" 2>&1 | grep -q "does not exist" || { echo "setup: migration job did not fail for the expected reason"; exit 1; }
[ -z "$(kubectl get job orders-db-init -n "$NS" -o name 2>/dev/null)" ] || { echo "setup: init job ran before the migration"; exit 1; }
