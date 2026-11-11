#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Hidden earlier revision: chart 1.0.0 with a hand-tuned replicaCount.
helm install notifier "$LEVEL_DIR/assets/notifier-1.0.0" -n "$NS" --set replicaCount=2 --wait --timeout 120s >/dev/null
[ "$(hm_release_chart notifier)" = "notifier-1.0.0" ] || { echo "setup: expected chart 1.0.0"; exit 1; }
# The CI upgrade the colleague ran: must fail.
if bash "$SANDBOX/ci-upgrade.sh" >"$HM_TMP/out.txt" 2>&1; then
  echo "setup: the --reuse-values upgrade should have failed"; exit 1
fi
grep -q "nil pointer evaluating interface {}.port" "$HM_TMP/out.txt" || { cat "$HM_TMP/out.txt"; exit 1; }
