#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed ticket-booking
[ "$(hm_release_revision ticket-booking)" -ge 3 ] || hm_fail "Release is still on revision $(hm_release_revision ticket-booking) - nothing new was deployed"
msel="$(hm_manifest_json ticket-booking | jq -r '[.[]|select(.kind=="Service")][0].spec.selector.color')"
[ "$msel" = "blue" ] || hm_fail "The release manifest's Service selects colour '$msel' - Helm still thinks traffic goes elsewhere"
lsel="$(hm_jsonpath service/ticket-booking '{.spec.selector.color}')"
[ "$lsel" = "blue" ] || hm_fail "The live Service selects colour '$lsel'"

hm_info "Checking traffic..."
hm_wait_rollout deployment/ticket-booking-blue "$NS" 90s
[ "$(hm_endpoints_count ticket-booking)" -ge 1 ] || hm_fail "Service ticket-booking has no ready endpoints"
hm_http_check http://ticket-booking >"$HM_TMP/body.txt" || hm_fail "http://ticket-booking does not answer"
grep -q "blue" "$HM_TMP/body.txt" || hm_fail "The answer does not come from the blue colour" "$HM_TMP/body.txt"

hm_info "Checking that green is still there for debugging..."
kubectl get deployment ticket-booking-green -n "$NS" >/dev/null 2>&1 || hm_fail "The green Deployment no longer exists"
greps="$(hm_jsonpath deployment/ticket-booking-green '{.spec.replicas}')"
[ "${greps:-0}" -ge 1 ] || hm_fail "The green Deployment was scaled to ${greps:-0} replicas - it must stay deployed for debugging"
[ "$(hm_jsonpath deployment/ticket-booking-green '{.spec.template.spec.containers[0].image}')" = "traefik/whoami:v1.99.0" ] \
  || hm_fail "The green Deployment was changed - it must be left exactly as it is for debugging"

hm_pass "Traffic is back on blue and green is parked for debugging."
