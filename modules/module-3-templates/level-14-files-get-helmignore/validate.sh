#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/legacy-site"
[ -f "$CHART/Chart.yaml" ] || hm_fail "legacy-site/Chart.yaml is missing from the workspace"
conf() { jq -r '[.[] | select(.kind=="ConfigMap") | .data["default.conf"]] | first // empty'; }

hm_info "Rendering the chart from the workspace..."
hm_render_json "$CHART" >"$HM_TMP/r.json" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
c="$(conf <"$HM_TMP/r.json")"
[ -n "$(echo "$c" | tr -d '[:space:]')" ] || hm_fail "The rendered ConfigMap has an empty default.conf"
echo "$c" | grep -q "listen 8080" && echo "$c" | grep -q "/healthz" || hm_fail "The rendered default.conf is not the nginx server block (listen 8080 + /healthz)"
hm_ok "The chart renders a real nginx configuration"

hm_info "Checking the release..."
hm_require_deployed site
rev="$(hm_release_revision site)"
[ "${rev:-0}" -ge 2 ] || hm_fail "Release site is still at revision ${rev:-?} - the fixed chart was never deployed"
m="$(hm_manifest_json site | conf)"
echo "$m" | grep -q "listen 8080" || hm_fail "The release manifest still has no nginx server block in default.conf"
live="$(kubectl get configmap site-nginx -n "$NS" -o jsonpath='{.data.default\.conf}')"
echo "$live" | grep -q "listen 8080" || hm_fail "The live ConfigMap site-nginx has no server block"
hm_wait_rollout deployment/site "$NS" 90s
[ "$(hm_endpoints_count site)" -ge 1 ] || hm_fail "Service site has no ready endpoints"
body=""; for _ in 1 2 3 4; do body="$(hm_http_check "http://site.$NS.svc.cluster.local/healthz")" && break; body=""; sleep 3; done
[ -n "$body" ] || hm_fail "Service site does not answer on /healthz"
echo "$body" | grep -q ok || hm_fail "/healthz did not return ok"

hm_pass "site serves its real configuration."
