#!/bin/bash
set -uo pipefail
source "$HM_LIB"
WANT='Harbor Light #2024'

hm_require_deployed ledger-api

hm_info "Checking the credential Helm manages..."
mp="$(hm_manifest_json ledger-api | jq -r '.[] | select(.kind=="Secret" and (.metadata.name|endswith("-db"))) | .data.DB_PASSWORD // empty' | base64 -d 2>/dev/null)"
[ "$mp" = "$WANT" ] || hm_fail "The Secret rendered by the release holds a different password than the one in the values file (${#mp} characters)"
lp="$(kubectl get secret ledger-api-db -n "$NS" -o jsonpath='{.data.DB_PASSWORD}' 2>/dev/null | base64 -d 2>/dev/null)"
[ "$lp" = "$WANT" ] || hm_fail "The live Secret ledger-api-db holds a different password (${#lp} characters)"
hm_ok "Secret carries the full password"

hm_info "Checking the workload..."
hm_wait_rollout deployment/ledger-api "$NS" 90s
ready="$(hm_jsonpath deployment/ledger-api '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 1 ] || hm_fail "Deployment ledger-api has no ready pod"
hm_pass "ledger-api passes the database credential check."
