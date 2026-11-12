#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/helpdesk"

hm_info "Checking that the chart renders..."
objs="$(hm_render_json "$CHART")" || true
[ -n "$objs" ] && [ "$objs" != "[]" ] || hm_fail "helm template cannot render the chart in your workspace" "$HM_TMP/render-err.txt"
bad="$(echo "$objs" | jq -r '[.[] | select((type!="object") or (.apiVersion==null) or (.kind==null))] | length')"
[ "$bad" = "0" ] || hm_fail "$bad rendered document(s) are not Kubernetes manifests (no apiVersion/kind)"
for k in Deployment Service ConfigMap; do
  echo "$objs" | jq -e --arg k "$k" 'any(.[]; .kind==$k)' >/dev/null || hm_fail "The chart no longer renders its $k"
done
helm lint "$CHART" >"$HM_TMP/lint.txt" 2>&1 || hm_fail "helm lint reports errors" "$HM_TMP/lint.txt"
hm_ok "Chart renders three manifests and lint passes"

hm_info "Checking the release..."
hm_require_deployed helpdesk
chart="$(hm_release_chart helpdesk)"
[ "$chart" = "helpdesk-1.0.0" ] || hm_fail "Release helpdesk runs chart '$chart'"
hm_wait_rollout deployment/helpdesk "$NS" 90s
[ "$(hm_endpoints_count helpdesk)" -ge 1 ] || hm_fail "Service helpdesk has no ready endpoints"

hm_pass "helpdesk is live."
