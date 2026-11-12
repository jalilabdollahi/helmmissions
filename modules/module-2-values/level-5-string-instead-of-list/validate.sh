#!/bin/bash
set -uo pipefail
source "$HM_LIB"

# Probe pods can race with DNS/endpoints right after a rollout: retry a few times.
http_retry() { local i out; for i in 1 2 3 4 5; do out="$(hm_http_check "$1")" && { echo "$out"; return 0; }; sleep 3; done; echo "$out"; return 1; }

CHART="$SANDBOX/cors-gateway"
lines() { jq -r '.[] | select(.kind=="ConfigMap" and .metadata.name=="hm-render-origins") | .data["origins.txt"]' | sed '/^$/d'; }

hm_info "Rendering with several origins supplied as a list..."
out2="$(hm_render_json "$CHART" --set 'allowedOrigins={https://a.example,https://b.example}')" || hm_fail "helm template fails when allowedOrigins is a list" "$HM_TMP/render-err.txt"
got="$(echo "$out2" | lines | tr '\n' ' ')"
[ "$got" = "https://a.example https://b.example " ] || hm_fail "With two origins, origins.txt reads '$got' instead of one origin per line"
hm_ok "The chart handles one or many origins"

hm_require_deployed cors-gateway
live="$(kubectl get configmap cors-gateway-origins -n "$NS" -o jsonpath='{.data.origins\.txt}' 2>/dev/null | sed '/^$/d')"
echo "$live" | grep -qx 'https://shop.example' || hm_fail "The live ConfigMap does not list https://shop.example"
hm_wait_rollout deployment/cors-gateway "$NS" 90s
body="$(http_retry http://cors-gateway/origins.txt)"
echo "$body" | grep -q 'https://shop.example' || hm_fail "The service does not serve the origin list"
hm_pass "cors-gateway publishes its origins."
