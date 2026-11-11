#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install rating-service "$SANDBOX/rating-service" -n "$NS" --wait --timeout 90s >/dev/null
if helm test rating-service -n "$NS" --timeout 60s >"$HM_TMP/test.txt" 2>&1; then
  echo "setup: the test suite passed — scenario is not broken"; exit 1
fi
grep -q "failed" "$HM_TMP/test.txt" || { cat "$HM_TMP/test.txt"; exit 1; }
