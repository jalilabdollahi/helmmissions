#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/ledger"

hm_info "Checking that CI's dependency build now succeeds..."
ws="$HM_TMP/ci"
mkdir -p "$ws"
cp -R "$CHART" "$ws/ledger"
cp -R "$SANDBOX/ledger-db" "$ws/ledger-db"
helm dependency build "$ws/ledger" >"$HM_TMP/build.txt" 2>&1 \
  || hm_fail "helm dependency build ./ledger still fails" "$HM_TMP/build.txt"
locked="$(hm_yaml_get "$CHART/Chart.lock" dependencies.0.version)"
[ "$locked" = '"0.4.0"' ] || hm_fail "Chart.lock pins ledger-db $locked, but Chart.yaml requires 0.4.0"
hm_ok "Chart.yaml and Chart.lock agree (ledger-db 0.4.0)"

hm_info "Checking the release..."
hm_require_deployed ledger
chart="$(hm_release_chart ledger)"
[ "$chart" = "ledger-0.3.0" ] || hm_fail "Release ledger runs chart '$chart', expected ledger-0.3.0 from the workspace"
dbver="$(hm_manifest_json ledger | jq -r '[.[] | select(.kind=="Deployment" and .metadata.name=="ledger-ledger-db")][0].metadata.labels["helm.sh/chart"] // ""')"
[ "$dbver" = "ledger-db-0.4.0" ] || hm_fail "The running database comes from '${dbver:-nothing}', not ledger-db-0.4.0 (the release still ships an old subchart)"

hm_info "Checking the workloads..."
hm_wait_rollout deployment/ledger-api "$NS" 90s
hm_wait_rollout deployment/ledger-ledger-db "$NS" 90s
wal="$(hm_jsonpath deployment/ledger-ledger-db '{.spec.template.spec.containers[0].env[?(@.name=="WAL_RETENTION_HOURS")].value}')"
[ "$wal" = "48" ] || hm_fail "WAL_RETENTION_HOURS is '$wal' (ledger/values.yaml asks for 48)"

hm_pass "ledger runs against ledger-db 0.4.0 and CI can rebuild it."
