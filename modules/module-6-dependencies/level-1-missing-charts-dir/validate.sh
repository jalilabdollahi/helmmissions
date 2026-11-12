#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/storefront"

hm_info "Checking the chart still declares its dependency..."
hm_yaml_get "$CHART/Chart.yaml" dependencies | jq -e 'type=="array" and any(.[]; .name=="session-cache")' >/dev/null \
  || hm_fail "storefront/Chart.yaml no longer declares the session-cache dependency"

hm_info "Checking the release..."
hm_require_deployed storefront
chart="$(hm_release_chart storefront)"
[ "$chart" = "storefront-0.2.0" ] || hm_fail "Release storefront runs chart '$chart', expected storefront-0.2.0 from the workspace"
hm_manifest_json storefront | jq -e 'any(.[]; .kind=="Deployment" and .metadata.name=="storefront-session-cache")' >/dev/null \
  || hm_fail "The storefront release does not contain the session cache (no Deployment storefront-session-cache in its manifest)"

hm_info "Checking the workloads..."
hm_wait_rollout deployment/storefront "$NS" 90s
hm_wait_rollout deployment/storefront-session-cache "$NS" 90s
[ "$(hm_endpoints_count storefront-session-cache)" -ge 1 ] || hm_fail "Service storefront-session-cache has no ready endpoints"

hm_pass "storefront is live together with its session cache."
