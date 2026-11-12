#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/order-sync"

hm_info "Checking that the setting is in the files the pipeline deploys with..."
[ -f "$SANDBOX/values-prod.yaml" ] || hm_fail "values-prod.yaml is missing from the workspace"
render="$(hm_render_json "$CHART" -f "$SANDBOX/values-prod.yaml")" || hm_fail "The chart does not render with values-prod.yaml" "$HM_TMP/render-err.txt"
pool="$(echo "$render" | jq -r '[.[]|select(.kind=="Deployment")][0].spec.template.spec.containers[0].env[]|select(.name=="DB_POOL_SIZE").value')"
[ "$pool" = "40" ] || hm_fail "Deploying the workspace chart with values-prod.yaml renders DB_POOL_SIZE='$pool' - the next pipeline run would bring the outage back"
hm_ok "chart + values-prod.yaml render DB_POOL_SIZE=40"

hm_info "Checking the release..."
hm_require_deployed order-sync
[ "$(hm_release_revision order-sync)" -ge 3 ] || hm_fail "Release is still on revision $(hm_release_revision order-sync) - nothing new was deployed"
case "$(hm_release_description order-sync)" in Rollback*) hm_fail "The newest revision is a rollback - it can't contain a setting that never existed in an earlier revision" ;; esac
rel_pool="$(hm_manifest_json order-sync | jq -r '[.[]|select(.kind=="Deployment")][0].spec.template.spec.containers[0].env[]|select(.name=="DB_POOL_SIZE").value')"
[ "$rel_pool" = "40" ] || hm_fail "The release manifest still says DB_POOL_SIZE=$rel_pool - Helm does not know about the fix"

hm_info "Checking the live workload..."
hm_wait_rollout deployment/order-sync "$NS" 90s
live="$(hm_jsonpath deployment/order-sync '{.spec.template.spec.containers[0].env[?(@.name=="DB_POOL_SIZE")].value}')"
[ "$live" = "40" ] || hm_fail "The live Deployment has DB_POOL_SIZE=$live"
hm_http_check http://order-sync >"$HM_TMP/body.txt" || hm_fail "http://order-sync does not answer"
grep -q "status=ok" "$HM_TMP/body.txt" || hm_fail "order-sync still reports a problem" "$HM_TMP/body.txt"

hm_pass "The pool size now lives in Git - the next deploy will keep it."
