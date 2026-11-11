#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/newsletter"

hm_info "Running the CI gate: helm lint --strict ..."
helm lint --strict "$CHART" >"$HM_TMP/lint.txt" 2>&1 || hm_fail "helm lint --strict still fails" "$HM_TMP/lint.txt"
hm_ok "helm lint --strict passes"

hm_info "Checking the chart still describes the same application..."
[ "$(hm_yaml_get "$CHART/Chart.yaml" name)" = '"newsletter"' ] || hm_fail "The chart name must stay 'newsletter' (lowercase)"
ver="$(hm_yaml_get "$CHART/Chart.yaml" version | jq -r .)"
echo "$ver" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$' || hm_fail "Chart version '$ver' is not SemVer (MAJOR.MINOR.PATCH)"
objs="$(hm_render_json "$CHART" --set 'x=1')" || true
[ -n "$objs" ] || hm_fail "The chart no longer renders" "$HM_TMP/render-err.txt"
kinds="$(echo "$objs" | jq -r '[.[].kind] | sort | join(" ")')"
[ "$kinds" = "ConfigMap Deployment Service" ] || hm_fail "The chart renders '$kinds' instead of its ConfigMap, Deployment and Service"
img="$(echo "$objs" | jq -r '[.[] | select(.kind=="Deployment")][0].spec.template.spec.containers[0].image')"
[ "$img" = "nginxinc/nginx-unprivileged:1.27-alpine" ] || hm_fail "The Deployment image changed to '$img'"
hm_ok "Same resources, SemVer chart version $ver"

hm_info "Checking the release..."
hm_require_deployed newsletter
chart="$(hm_release_chart newsletter)"
[ "$chart" = "newsletter-$ver" ] || hm_fail "Release newsletter runs '$chart' but the workspace chart is newsletter-$ver - install the fixed chart"
hm_wait_rollout deployment/newsletter "$NS" 90s

hm_pass "newsletter passes the CI gate and is deployed."
