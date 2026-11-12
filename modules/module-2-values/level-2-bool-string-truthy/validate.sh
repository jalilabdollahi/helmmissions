#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_require_deployed storefront

hm_info "Checking what the release manages..."
n="$(hm_manifest_json storefront | jq '[.[] | select(.kind=="Ingress")] | length')"
[ "$n" = "0" ] || hm_fail "The release manifest of storefront still contains $n Ingress object(s)"
live="$(kubectl get ingress -n "$NS" -o name 2>/dev/null | wc -l | tr -d ' ')"
[ "$live" = "0" ] || hm_fail "There is still an Ingress in namespace $NS"
hm_ok "No Ingress in the release or the namespace"

hm_info "Checking the computed value..."
typ="$(hm_all_values storefront | jq -r '.ingress.enabled | type + ":" + tostring')"
[ "$typ" = "boolean:false" ] || hm_fail "ingress.enabled is '$typ' in the computed values - expected a boolean false"

hm_wait_rollout deployment/storefront "$NS" 90s
[ "$(hm_endpoints_count storefront)" -ge 1 ] || hm_fail "Service storefront has no ready endpoints"
hm_pass "storefront is exposed only through the gateway."
