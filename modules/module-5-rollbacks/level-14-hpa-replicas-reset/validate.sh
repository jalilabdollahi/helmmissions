#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/thumbnail-svc"
dep() { jq -c '[.[]|select(.kind=="Deployment")][0]'; }

hm_info "Checking what the chart renders..."
on="$(hm_render_json "$CHART" | dep)" || hm_fail "The chart does not render" "$HM_TMP/render-err.txt"
echo "$on" | jq -e '.spec | has("replicas") | not' >/dev/null \
  || hm_fail "With autoscaling enabled the Deployment still sets replicas ($(echo "$on" | jq -c .spec.replicas)) - every deploy overrides the autoscaler"
off="$(hm_render_json "$CHART" --set autoscaling.enabled=false | dep)" || hm_fail "The chart does not render with autoscaling off" "$HM_TMP/render-err.txt"
[ "$(echo "$off" | jq -r '.spec.replicas')" = "2" ] || hm_fail "With autoscaling disabled the Deployment no longer gets replicas from replicaCount"
hm_render_json "$CHART" | jq -e 'any(.[]; .kind=="HorizontalPodAutoscaler")' >/dev/null || hm_fail "The HorizontalPodAutoscaler is gone from the chart"
hm_ok "Chart: replicas only when autoscaling is off"

hm_info "Checking the release..."
hm_require_deployed thumbnail-svc
[ "$(hm_release_revision thumbnail-svc)" -ge 3 ] || hm_fail "Release is still on revision $(hm_release_revision thumbnail-svc) - the fix was never deployed"
kubectl get hpa thumbnail-svc -n "$NS" >/dev/null 2>&1 || hm_fail "HPA thumbnail-svc does not exist in the cluster"

hm_info "Simulating the autoscaler and the next pipeline deploy..."
kubectl scale deployment/thumbnail-svc -n "$NS" --replicas=5 >/dev/null || hm_fail "Cannot scale the Deployment"
if [ -x "$SANDBOX/ci/deploy.sh" ]; then
  ( cd "$SANDBOX" && bash ci/deploy.sh ) >"$HM_TMP/deploy.txt" 2>&1 || hm_fail "The pipeline's deploy fails" "$HM_TMP/deploy.txt"
else
  helm upgrade thumbnail-svc "$CHART" -n "$NS" -f "$SANDBOX/values-prod.yaml" >"$HM_TMP/deploy.txt" 2>&1 || hm_fail "helm upgrade fails" "$HM_TMP/deploy.txt"
fi
r="$(hm_jsonpath deployment/thumbnail-svc '{.spec.replicas}')"
[ "$r" = "5" ] || hm_fail "After a deploy the Deployment has $r replicas - the autoscaler's 5 was overwritten"

hm_pass "Deploys no longer fight the autoscaler."
