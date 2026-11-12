#!/bin/bash
set -uo pipefail
source "$HM_LIB"

PROD_NS="$NS"; STG_NS=helmissions-staging
[ -f "$SANDBOX/deploy.sh" ] || hm_fail "deploy.sh is missing from the workspace"

hm_info "Checking the chart's dependencies in the workspace..."
helm dependency list "$SANDBOX/tideline" >"$HM_TMP/deps.txt" 2>&1 || hm_fail "helm dependency list failed" "$HM_TMP/deps.txt"
awk 'NR>1 && NF {print $1, $NF}' "$HM_TMP/deps.txt" | grep -qx "cache ok" || hm_fail "The workspace chart's dependencies are not consistent" "$HM_TMP/deps.txt"
hm_ok "Dependencies are consistent"

hm_info "Running the pipeline from the workspace: staging, then prod..."
bash "$SANDBOX/deploy.sh" staging >"$HM_TMP/d-stg.txt" 2>&1 || hm_fail "deploy.sh staging failed" "$HM_TMP/d-stg.txt"
bash "$SANDBOX/deploy.sh" prod >"$HM_TMP/d-prod.txt" 2>&1 || hm_fail "deploy.sh prod failed" "$HM_TMP/d-prod.txt"
hm_ok "Both pipeline stages ran cleanly"

hm_info "Checking the releases and their history..."
hm_require_deployed tideline "$PROD_NS"
hm_require_deployed tideline-staging "$STG_NS"
last="$(hm_history_json tideline "$PROD_NS" | jq -r '.[-1].status')"
case "$last" in pending*) hm_fail "Prod's newest revision is still in a pending state ($last)" ;; esac
for pair in "tideline:$PROD_NS" "tideline-staging:$STG_NS"; do
  rel="${pair%%:*}"; ns="${pair##*:}"
  ok="$(kubectl get job "$rel-migrate" -n "$ns" -o jsonpath='{.status.succeeded}' 2>/dev/null || true)"
  [ "${ok:-0}" -ge 1 ] 2>/dev/null || hm_fail "The database migration hook of $rel has not completed successfully"
done
hm_ok "Releases deployed, history clean, migrations completed"

hm_info "Checking the status pages..."
check() { # ns release replicas expected-db
  hm_wait_rollout "deployment/$2" "$1" 90s
  hm_wait_rollout "deployment/$2-cache" "$1" 90s
  for _ in $(seq 1 20); do
    n="$(kubectl get pods -n "$1" -l "app.kubernetes.io/instance=$2" --no-headers | wc -l | tr -d ' ')"
    [ "$n" = "$(( $3 + 1 ))" ] && break
    sleep 2
  done
  for _ in 1 2 3 4; do
    hm_http_check "http://$2/cgi-bin/status" "$1" >"$HM_TMP/p-$2.txt" 2>/dev/null
    grep -qx "status=ok" "$HM_TMP/p-$2.txt" && break
    sleep 3
  done
  grep -qx "status=ok" "$HM_TMP/p-$2.txt" || hm_fail "$2: status page is not healthy" "$HM_TMP/p-$2.txt"
  grep -qx "schema=13" "$HM_TMP/p-$2.txt" || hm_fail "$2: the database schema is not 13" "$HM_TMP/p-$2.txt"
  grep -qE "^cache=1\.2\.[0-9]+$" "$HM_TMP/p-$2.txt" || hm_fail "$2: the cache is not running 1.2.x" "$HM_TMP/p-$2.txt"
  grep -qx "db=tideline-db.$1" "$HM_TMP/p-$2.txt" || hm_fail "$2: the database host does not belong to namespace $1" "$HM_TMP/p-$2.txt"
}
check "$PROD_NS" tideline 2 
check "$STG_NS" tideline-staging 1
hm_pass "Tideline 2.0 is live in both environments. Incident resolved."
