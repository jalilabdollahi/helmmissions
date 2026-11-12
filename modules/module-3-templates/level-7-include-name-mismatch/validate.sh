#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/storefront"
[ -f "$CHART/Chart.yaml" ] || hm_fail "storefront/Chart.yaml is missing from the workspace"
labels() { jq -c --arg k "$1" '[.[] | select(.kind==$k) | .metadata.labels] | first // {}'; }

hm_info "Rendering the chart from the workspace..."
helm lint "$CHART" >"$HM_TMP/lint.txt" 2>&1 || hm_fail "helm lint reports errors" "$HM_TMP/lint.txt"
hm_render_json "$CHART" >"$HM_TMP/r.json" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
dl="$(labels Deployment <"$HM_TMP/r.json")"; sl="$(labels Service <"$HM_TMP/r.json")"
[ "$(echo "$sl" | jq -S -c .)" = "$(echo "$dl" | jq -S -c .)" ] || hm_fail "Service labels differ from the Deployment labels (service: $sl, deployment: $dl)"
for k in app.kubernetes.io/name app.kubernetes.io/instance app.kubernetes.io/version app.kubernetes.io/managed-by; do
  [ "$(echo "$sl" | jq -r --arg k "$k" '.[$k] // empty')" != "" ] || hm_fail "Service is missing the standard label $k"
done
hm_ok "The Service gets the same standard labels as the Deployment"

hm_info "Checking the release..."
hm_require_deployed shop
[ "$(hm_release_chart shop)" = "storefront-1.0.0" ] || hm_fail "Release shop was not deployed from the storefront chart"
live="$(kubectl get svc shop -n "$NS" -o json 2>/dev/null | jq -c '.metadata.labels')"
[ "$(echo "$live" | jq -r '."app.kubernetes.io/managed-by" // empty')" = "Helm" ] || hm_fail "The live Service shop lacks the standard labels (labels: $live)"
hm_wait_rollout deployment/shop "$NS" 90s
ready="$(hm_jsonpath deployment/shop '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment shop has ${ready:-0}/2 ready pods"
[ "$(hm_endpoints_count shop)" -ge 2 ] || hm_fail "Service shop has fewer than 2 ready endpoints"

hm_pass "shop is live under its new chart name."
