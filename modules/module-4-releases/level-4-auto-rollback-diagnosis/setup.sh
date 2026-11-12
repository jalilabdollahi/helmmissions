#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install telemetry-gw "$LEVEL_DIR/assets/telemetry-gw" -n "$NS" --wait --timeout 90s >/dev/null
# The pipeline's upgrade: atomic. Helm 4 renamed --atomic to --rollback-on-failure.
if [ "$(hm_helm_major)" -ge 4 ]; then flag=--rollback-on-failure; else flag=--atomic; fi
helm upgrade telemetry-gw "$SANDBOX/telemetry-gw" -n "$NS" "$flag" --timeout 60s >"$HM_TMP/upgrade.txt" 2>&1 || true
hist="$(hm_history_json telemetry-gw)"
[ "$(echo "$hist" | jq -r 'map(.status)|join(",")')" = "superseded,failed,deployed" ] \
  || { echo "setup: unexpected history"; echo "$hist" | jq -c '.[]|{revision,status}'; cat "$HM_TMP/upgrade.txt"; exit 1; }
[ "$(echo "$hist" | jq -r '.[-1].description')" = "Rollback to 1" ] || { echo "setup: no rollback revision"; exit 1; }
grep -q "every 15 minutes" "$HM_TMP/upgrade.txt" || { cat "$HM_TMP/upgrade.txt"; exit 1; }
