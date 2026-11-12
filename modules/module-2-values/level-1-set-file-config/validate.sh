#!/bin/bash
set -uo pipefail
source "$HM_LIB"

# Probe pods can race with DNS/endpoints right after a rollout: retry a few times.
http_retry() { local i out; for i in 1 2 3 4 5; do out="$(hm_http_check "$1")" && { echo "$out"; return 0; }; sleep 3; done; echo "$out"; return 1; }

SITE="$SANDBOX/site.conf"
[ -s "$SITE" ] || hm_fail "site.conf is missing or empty in the workspace"
hm_require_deployed landing

norm() { "$HM_PYTHON" -c 'import sys; print(sys.stdin.read().strip())'; }
want="$(norm <"$SITE")"

hm_info "Checking the ConfigMap Helm manages..."
manifest_cm="$(hm_manifest_json landing | jq -r '.[] | select(.kind=="ConfigMap" and .metadata.name=="landing-nginx") | .data["default.conf"] // empty' | norm)"
[ -n "$manifest_cm" ] || hm_fail "The release manifest has no ConfigMap landing-nginx with a default.conf key"
[ "$manifest_cm" = "$want" ] || hm_fail "Release landing renders default.conf as: '$(echo "$manifest_cm" | head -c 60)' - not the contents of site.conf"
live_cm="$(kubectl get configmap landing-nginx -n "$NS" -o json 2>/dev/null | jq -r '.data["default.conf"] // empty' | norm)"
[ "$live_cm" = "$want" ] || hm_fail "The live ConfigMap landing-nginx differs from site.conf"
hm_ok "ConfigMap landing-nginx carries the real site.conf"

hm_info "Checking the workload..."
hm_wait_rollout deployment/landing "$NS" 90s
ready="$(hm_jsonpath deployment/landing '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 1 ] || hm_fail "Deployment landing has no ready pod"
body="$(http_retry http://landing/)"
echo "$body" | grep -q "Welcome to Landing" || hm_fail "The landing Service does not serve the page from site.conf (got: '${body:0:60}')"

hm_pass "landing serves the real site.conf."
