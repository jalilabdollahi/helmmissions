#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Hidden history: release `ledger` runs chart ledger-0.2.0 built against ledger-db 0.3.0.
# Its Chart.lock and charts/ tarball are what the workspace still contains.
ws="$HM_TMP/history"
mkdir -p "$ws"
cp -R "$SANDBOX/ledger" "$ws/ledger"
cp -R "$LEVEL_DIR/assets/ledger-db-0.3.0" "$ws/ledger-db"
cp "$LEVEL_DIR/assets/ledger-0.2.0/Chart.yaml" "$ws/ledger/Chart.yaml"
helm dependency update "$ws/ledger" >/dev/null
helm install ledger "$ws/ledger" -n "$NS" --wait --timeout 120s >/dev/null
hm_assert_status ledger deployed
cp "$ws/ledger/Chart.lock" "$SANDBOX/ledger/Chart.lock"
mkdir -p "$SANDBOX/ledger/charts"
cp "$ws/ledger/charts/"*.tgz "$SANDBOX/ledger/charts/"

# The workspace now says 0.4.0 in Chart.yaml but 0.3.0 in Chart.lock: CI's build step must refuse.
if helm dependency build "$SANDBOX/ledger" >"$HM_TMP/build.txt" 2>&1; then
  echo "setup: dependency build succeeded — scenario is not broken"; exit 1
fi
grep -q "out of sync with the dependencies file" "$HM_TMP/build.txt" || { cat "$HM_TMP/build.txt"; exit 1; }
