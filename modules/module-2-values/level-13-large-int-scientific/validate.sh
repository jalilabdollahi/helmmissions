#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/upload-proxy"
limit_of() { jq -r '.[] | select(.kind=="ConfigMap") | .data.MAX_UPLOAD_BYTES'; }

hm_info "Rendering the chart with its defaults..."
out="$(hm_render_json "$CHART")" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
v="$(echo "$out" | limit_of)"
[ "$v" = "1048576" ] || hm_fail "The default renders MAX_UPLOAD_BYTES as '$v' instead of 1048576"

hm_info "Rendering with 5242880 supplied in a values file..."
printf 'maxUploadBytes: 5242880\n' > "$HM_TMP/override.yaml"
out="$(hm_render_json "$CHART" -f "$HM_TMP/override.yaml")" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
v="$(echo "$out" | limit_of)"
[ "$v" = "5242880" ] || hm_fail "An override of 5242880 from a values file renders as '$v' - the chart should print plain integers"
out="$(hm_render_json "$CHART" --set maxUploadBytes=5242880)" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
[ "$(echo "$out" | limit_of)" = "5242880" ] || hm_fail "--set maxUploadBytes=5242880 does not render as 5242880"
hm_ok "Whole numbers render as plain integers"

hm_require_deployed upload-proxy
live="$(kubectl get configmap upload-proxy-limits -n "$NS" -o jsonpath='{.data.MAX_UPLOAD_BYTES}')"
[ "$live" = "1048576" ] || hm_fail "The live ConfigMap holds '$live'"
hm_wait_rollout deployment/upload-proxy "$NS" 90s
hm_pass "upload-proxy enforces a 1048576 byte limit."
