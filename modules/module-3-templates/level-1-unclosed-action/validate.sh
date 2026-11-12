#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/pressroom"
[ -f "$CHART/Chart.yaml" ] || hm_fail "pressroom/Chart.yaml is missing from the workspace"

hm_info "Rendering the chart from the workspace..."
helm lint "$CHART" >"$HM_TMP/lint.txt" 2>&1 || hm_fail "helm lint reports errors" "$HM_TMP/lint.txt"
hm_render_json "$CHART" --set site.name=ProbeName-7431 >"$HM_TMP/render.json" || hm_fail "helm template still fails" "$HM_TMP/render-err.txt"
n="$(jq '[.[] | select(.kind=="ConfigMap") | .data[]? | select(contains("ProbeName-7431"))] | length' "$HM_TMP/render.json")"
[ "$n" -ge 1 ] || hm_fail "The rendered homepage does not follow site.name - the name is hard-coded or missing"
hm_ok "The chart renders and the homepage follows site.name"

hm_info "Checking the release..."
hm_require_deployed pressroom
[ "$(hm_release_chart pressroom)" = "pressroom-0.3.0" ] || hm_fail "Release pressroom was not deployed from the pressroom chart in the workspace"
want="$(hm_yaml_get "$CHART/values.yaml" site.name | jq -r .)"
live="$(hm_manifest_json pressroom | jq -r '[.[] | select(.kind=="ConfigMap") | .data[]?] | join("\n")')"
echo "$live" | grep -qF "$want" || hm_fail "The release's homepage does not contain the site name '$want'"

hm_info "Checking the workload..."
hm_wait_rollout deployment/pressroom "$NS" 90s
[ "$(hm_endpoints_count pressroom)" -ge 1 ] || hm_fail "Service pressroom has no ready endpoints"
page=""; for _ in 1 2 3 4; do page="$(hm_http_check http://pressroom.$NS.svc.cluster.local)" && break; page=""; sleep 3; done
[ -n "$page" ] || hm_fail "Service pressroom does not answer over HTTP"
echo "$page" | grep -qF "$want" || hm_fail "The page served by pressroom does not show the site name"

hm_pass "pressroom is live and its homepage follows the values."
