#!/bin/bash
set -euo pipefail
source "$HM_LIB"

C="$SANDBOX/geo-lookup"
# rev 1: the good configuration (this revision will be pruned)
helm install geo-lookup "$C" -n "$NS" --set provider=maps-v2 --set ttl=300 --wait --timeout 90s >/dev/null
# rev 2-4: the migration to a new provider goes wrong in three steps; --history-max 3 keeps only the last three
helm upgrade geo-lookup "$C" -n "$NS" --history-max 3 --reuse-values --set provider=maps-v1 >/dev/null
helm upgrade geo-lookup "$C" -n "$NS" --history-max 3 --reuse-values --set ttl=0 >/dev/null
helm upgrade geo-lookup "$C" -n "$NS" --history-max 3 --reset-values -f "$SANDBOX/values-prod.yaml" --wait --timeout 90s >/dev/null

hm_assert_status geo-lookup deployed
first="$(hm_history_json geo-lookup | jq -r '.[0].revision')"
[ "$first" = "2" ] || { echo "setup: history should start at revision 2, starts at $first"; exit 1; }
kubectl get configmap geo-lookup-nginx -n "$NS" -o jsonpath='{.data.default\.conf}' | grep -q "is retired" || { echo "setup: the configuration should be the broken one"; exit 1; }
