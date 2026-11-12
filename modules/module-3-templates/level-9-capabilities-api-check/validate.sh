#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/docs-portal"
[ -f "$CHART/Chart.yaml" ] || hm_fail "docs-portal/Chart.yaml is missing from the workspace"
ing_api() { jq -r '[.[] | select(.kind=="Ingress") | .apiVersion] | first // empty'; }

hm_info "Rendering the chart against this cluster's API capabilities..."
[ "$(hm_yaml_get "$CHART/values.yaml" ingress.enabled)" = "true" ] || hm_fail "ingress.enabled is no longer true in values.yaml - the Ingress must stay"
if [ "$(hm_helm_major)" -ge 4 ]; then CAP=--dry-run=server; else CAP=--validate; fi
hm_render_json "$CHART" "$CAP" >"$HM_TMP/r.json" || hm_fail "helm template against the live cluster fails" "$HM_TMP/render-err.txt"
api="$(ing_api <"$HM_TMP/r.json")"
[ "$api" = "networking.k8s.io/v1" ] || hm_fail "Against the live cluster the chart renders an Ingress with apiVersion '${api:-none}', expected networking.k8s.io/v1"
spec="$(jq -c '[.[] | select(.kind=="Ingress") | .spec.rules[0].http.paths[0].backend.service.name] | first // empty' "$HM_TMP/r.json")"
[ -n "$spec" ] && [ "$spec" != "null" ] || hm_fail "The v1 Ingress has no backend.service - the v1 schema was not used for the spec"
hm_ok "The chart renders a v1 Ingress"

hm_info "Checking the release..."
hm_require_deployed portal
[ "$(hm_release_chart portal)" = "docs-portal-4.1.0" ] || hm_fail "Release portal was not deployed from the docs-portal chart"
[ "$(hm_manifest_json portal | ing_api)" = "networking.k8s.io/v1" ] || hm_fail "The release manifest has no networking.k8s.io/v1 Ingress"
live="$(kubectl get ingress portal -n "$NS" -o jsonpath='{.apiVersion}/{.spec.rules[0].host}' 2>/dev/null)" || hm_fail "Ingress portal does not exist in the cluster"
[ "$live" = "networking.k8s.io/v1/$(hm_yaml_get "$CHART/values.yaml" ingress.host | jq -r .)" ] || hm_fail "Live Ingress portal looks wrong ($live)"
hm_wait_rollout deployment/portal "$NS" 90s
[ "$(hm_endpoints_count portal)" -ge 1 ] || hm_fail "Service portal has no ready endpoints"

hm_pass "portal is deployed with a v1 Ingress."
