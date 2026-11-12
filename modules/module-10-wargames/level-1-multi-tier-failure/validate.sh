#!/bin/bash
set -uo pipefail
source "$HM_LIB"

env_of() { jq -r --arg n "$1" '[.[]|select(.kind=="Deployment")][0].spec.template.spec.containers[0].env[]?|select(.name==$n).value'; }

hm_info "Checking the three releases..."
for r in ledger-db ledger-api ledger-web; do
  st="$(hm_release_status "$r")"
  [ -n "$st" ] || hm_fail "Release '$r' does not exist in namespace $NS"
  [ "$st" = "deployed" ] || hm_fail "Release '$r' is in state '$st'"
done
hm_ok "All three releases are deployed"

hm_info "Checking the database migration..."
job_ok="$(kubectl get job ledger-db-migrate -n "$NS" -o jsonpath='{.status.succeeded}' 2>/dev/null || true)"
[ "${job_ok:-0}" -ge 1 ] 2>/dev/null || hm_fail "The database migration job has not completed successfully"
hm_ok "Migration job completed"

hm_info "Checking the pods..."
for app in ledger-db ledger-api ledger-web; do
  hm_wait_rollout "deployment/$app" "$NS" 60s
done

hm_info "Checking the workspace matches the cluster..."
for pair in "ledger-api:DB_HOST" "ledger-web:API_UPSTREAM"; do
  chart="${pair%%:*}"; var="${pair##*:}"
  want="$(hm_render_json "$SANDBOX/$chart" | env_of "$var")" || want=""
  have="$(hm_manifest_json "$chart" | env_of "$var")"
  [ -n "$want" ] && [ "$want" = "$have" ] || hm_fail "$chart: what the workspace would deploy ('$want') differs from what is running ('$have')"
done
want="$(hm_render_json "$SANDBOX/ledger-db" | jq -r '[.[]|select(.kind=="Job")][0].spec.template.spec.containers[0].env[0].value')"
[ "$want" = "v3" ] || hm_fail "ledger-db in the workspace would run migration target '$want'"
hm_ok "Workspace and cluster agree"

hm_info "Checking the stack end to end..."
for _ in 1 2 3; do
  hm_http_check http://ledger-web/cgi-bin/balance >"$HM_TMP/b.txt" 2>/dev/null
  grep -q "web ok -> api ok -> db pong schema=v3" "$HM_TMP/b.txt" && break
  sleep 4
done
grep -q "web ok -> api ok -> db pong schema=v3" "$HM_TMP/b.txt" || hm_fail "The health page does not report a healthy stack" "$HM_TMP/b.txt"
hm_pass "Three tiers are back, in order."
