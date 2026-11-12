#!/bin/bash
set -euo pipefail
source "$HM_LIB"

C="$SANDBOX/settlement-batch"
helm install settlement-batch "$C" -n "$NS" --wait --timeout 90s >/dev/null
# revision 2: a tag that doesn't exist; Recreate strategy means the working pod is gone
helm upgrade settlement-batch "$C" -n "$NS" --set image.tag=v1.99.0 >/dev/null
# the first, failed, rollback attempt (the pre-rollback hook fails)
helm rollback settlement-batch 1 -n "$NS" --timeout 60s >"$HM_TMP/rb.txt" 2>&1 && { echo "setup: rollback unexpectedly worked"; exit 1; }
grep -q "settlement-batch-drain" "$HM_TMP/rb.txt" || { cat "$HM_TMP/rb.txt"; exit 1; }
img="$(hm_jsonpath deployment/settlement-batch '{.spec.template.spec.containers[0].image}')"
[ "$img" = "traefik/whoami:v1.99.0" ] || { echo "setup: live image is $img"; exit 1; }
