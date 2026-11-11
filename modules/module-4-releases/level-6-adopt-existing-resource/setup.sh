#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The hand-made ConfigMap: no Helm metadata, values that differ from the chart, plus a legacy key.
kubectl create configmap desk-settings -n "$NS" \
  --from-literal=MAX_OPEN_TICKETS=50 --from-literal=LEGACY_QUEUE=true >/dev/null

if helm install support-desk "$SANDBOX/support-desk" -n "$NS" >"$HM_TMP/install.txt" 2>&1; then
  echo "setup: install succeeded — scenario is not broken"; exit 1
fi
grep -q "invalid ownership metadata" "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
[ -z "$(hm_release_status support-desk)" ] || { echo "setup: a release record exists"; exit 1; }
