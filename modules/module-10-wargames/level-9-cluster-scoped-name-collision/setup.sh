#!/bin/bash
set -euo pipefail
source "$HM_LIB"
kubectl create namespace helmissions-team-a >/dev/null
kubectl create namespace helmissions-team-b >/dev/null
cd "$SANDBOX"
helm install team-a ./collector -n helmissions-team-a -f values/team-a.yaml --wait --timeout 90s >/dev/null
helm install team-b ./collector -n helmissions-team-b -f values/team-b.yaml --wait --timeout 30s >"$HM_TMP/b.txt" 2>&1 && { echo "setup: team-b install unexpectedly worked"; exit 1; }
grep -q "exists and cannot be imported into the current release" "$HM_TMP/b.txt" || { cat "$HM_TMP/b.txt"; exit 1; }
hm_assert_status team-a deployed helmissions-team-a
