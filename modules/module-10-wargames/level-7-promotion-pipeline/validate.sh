#!/bin/bash
set -uo pipefail
source "$HM_LIB"

DEV=helmissions-dev; STG=helmissions-staging; PROD="$NS"
[ -f "$SANDBOX/pipeline.sh" ] || hm_fail "pipeline.sh is missing from the workspace"

hm_info "Proving the pipeline stops at a failing stage (staging is made to fail in a throwaway copy)..."
rm -rf "$HM_TMP/ws" "$HM_TMP/shim"; mkdir -p "$HM_TMP/shim"
cp -R "$SANDBOX" "$HM_TMP/ws"
REAL_HELM="$(command -v helm)"
cat >"$HM_TMP/shim/helm" <<SHIM
#!/bin/bash
case "\$*" in
  *billing-staging*) case "\$1" in upgrade|install) echo "Error: simulated staging outage" >&2; exit 1;; esac ;;
esac
exec "$REAL_HELM" "\$@"
SHIM
chmod +x "$HM_TMP/shim/helm"
rev_before="$(hm_release_revision billing "$PROD")"
PATH="$HM_TMP/shim:$PATH" bash "$HM_TMP/ws/pipeline.sh" >"$HM_TMP/sabotage.txt" 2>&1
rc=$?
rev_after="$(hm_release_revision billing "$PROD")"
[ "$rev_before" = "$rev_after" ] || hm_fail "With staging failing, the pipeline still went on to deploy prod (revision $rev_before -> $rev_after)" "$HM_TMP/sabotage.txt"
[ "$rc" -ne 0 ] || hm_fail "With staging failing, the pipeline still exited 0" "$HM_TMP/sabotage.txt"
hm_ok "A failing stage stops the pipeline before prod"

hm_info "Running the real pipeline..."
bash "$SANDBOX/pipeline.sh" >"$HM_TMP/run.txt" 2>&1 || hm_fail "pipeline.sh failed" "$HM_TMP/run.txt"
hm_ok "pipeline.sh succeeded"

page() { # namespace service
  for _ in 1 2 3 4; do
    hm_http_check "http://$2/" "$1" >"$HM_TMP/page-$2.txt" 2>/dev/null && return 0
    sleep 3
  done
  return 1
}
check_env() { # ns release env replicas payments db
  hm_require_deployed "$2" "$1"
  hm_wait_rollout "deployment/$2" "$1" 90s
  for _ in $(seq 1 20); do
    n="$(kubectl get pods -n "$1" -l "app.kubernetes.io/instance=$2" --no-headers | wc -l | tr -d ' ')"
    [ "$n" = "$4" ] && break
    sleep 2
  done
  r="$(hm_pods_json "app.kubernetes.io/instance=$2" "$1" | jq '[.[]|select(.status.containerStatuses[0].ready==true)]|length')"
  [ "$r" = "$4" ] || hm_fail "$2 has $r ready pods, expected $4"
  page "$1" "$2" || hm_fail "$2 does not answer"
  for want in "environment=$3" "build=1.36" "payments=$5" "database=$6"; do
    grep -qx "$want" "$HM_TMP/page-$2.txt" || hm_fail "$2: page does not say '$want'" "$HM_TMP/page-$2.txt"
  done
}
hm_info "Checking the three environments..."
check_env "$DEV" billing-dev dev 1 sandbox billing-db.helmissions-dev
check_env "$STG" billing-staging staging 1 sandbox billing-db.helmissions-staging
check_env "$PROD" billing prod 2 live billing-db.helmissions
stg_tag="$(hm_user_values billing-staging "$STG" | jq -r '.image.tag // empty')"
prod_tag="$(hm_user_values billing "$PROD" | jq -r '.image.tag // empty')"
[ -n "$prod_tag" ] && [ "$stg_tag" = "$prod_tag" ] || hm_fail "Prod does not run the build staging ran (staging '$stg_tag', prod '$prod_tag')"
hm_pass "The promotion pipeline works, and it stops when it should."
