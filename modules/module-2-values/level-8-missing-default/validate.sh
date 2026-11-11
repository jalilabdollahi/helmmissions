#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/fetcher"
timeout_of() { jq -r '.[] | select(.kind=="ConfigMap") | .data["fetcher.env"]' | grep '^FETCH_TIMEOUT=' | head -1; }

hm_info "Rendering without http.timeout..."
out="$(hm_render_json "$CHART" --set http.timeout=null)" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
t="$(echo "$out" | timeout_of)"
[ "$t" = "FETCH_TIMEOUT=30" ] || hm_fail "When http.timeout is not set the chart renders '$t' instead of FETCH_TIMEOUT=30"

hm_info "Rendering with an explicit http.timeout..."
out="$(hm_render_json "$CHART" --set http.timeout=45)" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
t="$(echo "$out" | timeout_of)"
[ "$t" = "FETCH_TIMEOUT=45" ] || hm_fail "An explicit http.timeout=45 renders '$t' - overrides must keep working"
hm_ok "Default and override both behave"

hm_require_deployed fetcher
live="$(kubectl get configmap fetcher-config -n "$NS" -o jsonpath='{.data.fetcher\.env}' | grep '^FETCH_TIMEOUT=')"
[ "$live" = "FETCH_TIMEOUT=30" ] || hm_fail "The live ConfigMap has '$live'"
hm_wait_rollout deployment/fetcher "$NS" 90s
hm_pass "fetcher polls with a 30 second timeout."
