#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install queue-worker "$SANDBOX/queue-worker" -n "$NS" -f "$SANDBOX/values-prod.yaml" --wait --timeout 120s >/dev/null
hm_assert_status queue-worker deployed
[ "$(hm_jsonpath deployment/queue-worker '{.spec.replicas}')" = 1 ] || { echo "setup: expected the typo to leave 1 replica"; exit 1; }
helm get values queue-worker -n "$NS" -o json | jq -e 'has("replicaCnt")' >/dev/null || { echo "setup: typo not recorded"; exit 1; }
