#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/checkout"
envof() { jq -r --arg n "$1" '[.[]|select(.kind=="Deployment")][0].spec.template.spec.containers[0].env[]|select(.name==$n).value'; }

hm_info "Checking what the pipeline would deploy..."
[ -f "$SANDBOX/values-prod.yaml" ] || hm_fail "values-prod.yaml is missing from the workspace"
render="$(hm_render_json "$CHART" -f "$SANDBOX/values-prod.yaml")" || hm_fail "The chart does not render with values-prod.yaml" "$HM_TMP/render-err.txt"
[ "$(echo "$render" | envof PAYMENT_PROVIDER)" = "stripe-v2" ] || hm_fail "Chart + values-prod.yaml would deploy payment provider '$(echo "$render" | envof PAYMENT_PROVIDER)'"
t="$(echo "$render" | envof PAYMENT_TIMEOUT_MS)"
[ "${t:-0}" -ge 1000 ] 2>/dev/null || hm_fail "Chart + values-prod.yaml would deploy a payment timeout of ${t}ms - the next pipeline run brings the outage back"
hm_ok "The pipeline's configuration renders working payment settings"

hm_info "Checking the release..."
hm_require_deployed checkout
[ "$(hm_release_revision checkout)" -ge 4 ] || hm_fail "Release is still on revision $(hm_release_revision checkout)"
rel="$(hm_manifest_json checkout)"
[ "$(echo "$rel" | envof PAYMENT_PROVIDER)" = "stripe-v2" ] || hm_fail "The release manifest still has payment provider '$(echo "$rel" | envof PAYMENT_PROVIDER)'"
rt="$(echo "$rel" | envof PAYMENT_TIMEOUT_MS)"
[ "${rt:-0}" -ge 1000 ] 2>/dev/null || hm_fail "The release manifest still has a payment timeout of ${rt}ms"

hm_info "Checking the live Deployment for leftovers..."
live="$(kubectl get deployment checkout -n "$NS" -o json | jq -c '[.spec.template.spec.containers[0].env[].name]')"
echo "$live" | jq -e 'index("FORCE_FALLBACK")|not' >/dev/null || hm_fail "The live Deployment still carries an environment variable that is in no revision of the release ($live)"
kubectl get deployment checkout -n "$NS" -o json | jq -e '.spec.template.spec.containers[0].env | map(select(.name=="PAYMENT_PROVIDER" and .value=="stripe-v2")) | length == 1' >/dev/null || hm_fail "The live Deployment does not use the working payment provider"

hm_info "Checking service health..."
hm_wait_rollout deployment/checkout "$NS" 90s
for _ in 1 2 3 4; do
  hm_http_check http://checkout/checkout.txt >"$HM_TMP/c.txt" || hm_fail "http://checkout does not answer"
  grep -q "checkout: ok" "$HM_TMP/c.txt" && break
  sleep 3
done
grep -q "checkout: ok" "$HM_TMP/c.txt" || hm_fail "Checkout is still unhealthy" "$HM_TMP/c.txt"

hm_pass "Checkout is back, clean, and the next deploy will keep it that way."
