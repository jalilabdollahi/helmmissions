#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/payments-gw"
[ -f "$CHART/Chart.yaml" ] || hm_fail "payments-gw/Chart.yaml is missing from the workspace"
# effective plain-text value of key api-key in a rendered/live Secret manifest array on stdin (data is base64, stringData plain)
secret_plain() {
  jq -r '[.[] | select(.kind=="Secret")] | first // {} | if (.stringData["api-key"]? // null) != null then .stringData["api-key"] elif (.data["api-key"]? // null) != null then (.data["api-key"] | @base64d) else empty end' 2>/dev/null
}

hm_info "Rendering the chart from the workspace..."
hm_render_json "$CHART" --set provider.apiKey=sk-probe-Xy12 >"$HM_TMP/r.json" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
[ "$(secret_plain <"$HM_TMP/r.json")" = "sk-probe-Xy12" ] || hm_fail "The rendered Secret does not decode to provider.apiKey (got '$(secret_plain <"$HM_TMP/r.json")')"
hm_ok "The Secret decodes to the key in values"

hm_info "Checking the release..."
hm_require_deployed gateway
[ "$(hm_release_chart gateway)" = "payments-gw-0.12.0" ] || hm_fail "Release gateway was not deployed from the payments-gw chart"
want="$(hm_yaml_get "$CHART/values.yaml" provider.apiKey | jq -r .)"
live="$(kubectl get secret gateway-provider -n "$NS" -o jsonpath='{.data.api-key}' 2>/dev/null | base64 -d 2>/dev/null)"
[ "$live" = "$want" ] || hm_fail "The live Secret gateway-provider does not decode to the provider.apiKey value"
[ "$(hm_manifest_json gateway | secret_plain)" = "$want" ] || hm_fail "The release manifest's Secret does not decode to provider.apiKey"
hm_wait_rollout deployment/gateway "$NS" 90s

hm_pass "gateway holds its provider key."
