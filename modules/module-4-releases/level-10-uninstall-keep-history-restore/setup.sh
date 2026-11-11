#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install loyalty-points "$LEVEL_DIR/assets/v1/loyalty-points" -n "$NS" --wait --timeout 90s >/dev/null
helm upgrade loyalty-points "$LEVEL_DIR/assets/v2/loyalty-points" -n "$NS" \
  --set replicaCount=2 --set tier.goldThreshold=500 --wait --timeout 90s >/dev/null
helm uninstall loyalty-points -n "$NS" --keep-history >/dev/null

hist="$(hm_history_json loyalty-points)"
[ "$(echo "$hist" | jq -r 'map(.status)|join(",")')" = "superseded,uninstalled" ] \
  || { echo "setup: unexpected history"; echo "$hist" | jq -c '.[]|{revision,status}'; exit 1; }
[ -z "$(hm_release_status loyalty-points)" ] || [ "$(hm_release_status loyalty-points)" = "uninstalled" ] || exit 1
[ -z "$(kubectl get deployment loyalty-points -n "$NS" -o name 2>/dev/null)" ] || { echo "setup: deployment still exists"; exit 1; }
