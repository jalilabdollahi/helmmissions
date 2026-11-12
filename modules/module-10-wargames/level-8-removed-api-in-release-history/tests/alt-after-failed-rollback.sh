#!/bin/bash
# Alternative path: the engineer tries `helm rollback` first (it fails and leaves pending-rollback), deletes that revision's record, then fixes everything.
set -euo pipefail
source "$HM_LIB"
helm rollback edge-gateway 1 -n "$NS" >/dev/null 2>&1 || true
last="$(helm history edge-gateway -n "$NS" -o json | jq -r '.[-1] | "\(.revision) \(.status)"')"
[ "${last#* }" = "pending-rollback" ] && kubectl delete secret "sh.helm.release.v1.edge-gateway.v${last%% *}" -n "$NS"
bash "$LEVEL_DIR/solve.sh"
