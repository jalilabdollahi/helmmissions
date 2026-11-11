#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/dispatch"
[ -f "$CHART/Chart.yaml" ] || hm_fail "dispatch/Chart.yaml is missing from the workspace"
appenv() { jq -r '[.[] | select(.kind=="Deployment") | .spec.template.spec.containers[0].env[]? | select(.name=="APP_ENV") | .value] | first // empty'; }

hm_info "Rendering the chart from the workspace..."
hm_render_json "$CHART" --set environment=staging >"$HM_TMP/r.json" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
[ "$(appenv <"$HM_TMP/r.json")" = "STAGING" ] || hm_fail "With environment=staging the worker gets APP_ENV='$(appenv <"$HM_TMP/r.json")', expected STAGING"
hm_ok "APP_ENV follows the environment value, in capitals"

hm_info "Checking the release..."
hm_require_deployed dispatch
[ "$(hm_release_chart dispatch)" = "dispatch-0.9.0" ] || hm_fail "Release dispatch was not deployed from the dispatch chart"
[ "$(hm_manifest_json dispatch | appenv)" = "PRODUCTION" ] || hm_fail "The release manifest has APP_ENV='$(hm_manifest_json dispatch | appenv)', expected PRODUCTION"
hm_wait_rollout deployment/dispatch-worker "$NS" 90s
v="$(kubectl get pods -n "$NS" -l app=dispatch -o json | jq -r '.items[0].spec.containers[0].env[] | select(.name=="APP_ENV") | .value')"
[ "$v" = "PRODUCTION" ] || hm_fail "The running pod has APP_ENV='$v'"

hm_pass "dispatch is up and shouting its environment name."
