#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
st="$(helm history edge-gateway -n "$NS" -o json 2>/dev/null | jq -r '.[-1].status // empty')"
[ -n "$st" ] || hm_fail "Release edge-gateway does not exist in namespace $NS"
[ "$st" = "deployed" ] || hm_fail "Release edge-gateway is in state '$st'"
rev="$(helm history edge-gateway -n "$NS" -o json | jq -r '.[-1].revision')"
[ "${rev:-0}" -ge 3 ] 2>/dev/null || hm_fail "Release edge-gateway is still on revision $rev - the 1.4.0 chart has not been released as a new revision"
chart="$(hm_release_chart edge-gateway)"
[ "$chart" = "edge-gateway-1.4.0" ] || hm_fail "The deployed chart is '$chart', expected edge-gateway-1.4.0"
first="$(hm_history_json edge-gateway | jq -r '.[0] | "\(.revision) \(.description)"')"
[ "$first" = "1 Install complete" ] || hm_fail "The release history of edge-gateway was not preserved (oldest entry: '$first')"
hm_ok "Revision $rev of edge-gateway-1.4.0 is deployed on top of the existing history"

hm_info "Checking API versions in the release and in the workspace..."
m="$(hm_manifest_json edge-gateway)"
echo "$m" | jq -e '[.[]|select(.kind=="PodDisruptionBudget")][0].apiVersion=="policy/v1"' >/dev/null || hm_fail "The release manifest has a PodDisruptionBudget with a removed API version"
echo "$m" | jq -e '[.[]|select(.kind=="HorizontalPodAutoscaler")][0].apiVersion=="autoscaling/v2"' >/dev/null || hm_fail "The release manifest has a HorizontalPodAutoscaler with a removed API version"
r="$(hm_render_json "$SANDBOX/edge-gateway")" || hm_fail "The workspace chart does not render" "$HM_TMP/render-err.txt"
echo "$r" | jq -e '[.[]|select(.kind=="PodDisruptionBudget")][0].apiVersion=="policy/v1" and [.[]|select(.kind=="HorizontalPodAutoscaler")][0].apiVersion=="autoscaling/v2"' >/dev/null || hm_fail "The workspace chart still renders removed API versions"
echo "$r" | jq -e '[.[]|select(.kind=="HorizontalPodAutoscaler")][0].spec | .minReplicas==2 and .maxReplicas==4' >/dev/null || hm_fail "The workspace chart does not render autoscaling between 2 and 4 replicas"
hm_ok "Release and workspace use served API versions"

hm_info "Checking the live objects..."
kubectl get pdb edge-gateway -n "$NS" >/dev/null 2>&1 || hm_fail "PodDisruptionBudget edge-gateway does not exist"
hpa="$(kubectl get hpa edge-gateway -n "$NS" -o json 2>/dev/null)" || hm_fail "HorizontalPodAutoscaler edge-gateway does not exist"
echo "$hpa" | jq -e '.spec.minReplicas==2 and .spec.maxReplicas==4' >/dev/null || hm_fail "The live autoscaler is not set to 2-4 replicas"
hm_wait_rollout deployment/edge-gateway "$NS" 90s
n="$(hm_pods_json app.kubernetes.io/name=edge-gateway | jq '[.[]|select(.status.containerStatuses[0].ready==true)]|length')"
[ "$n" -ge 2 ] || hm_fail "Only $n gateway pods are ready"

hm_info "Checking the gateway answers..."
for _ in 1 2 3 4; do
  hm_http_check http://edge-gateway/ >"$HM_TMP/g.txt" 2>/dev/null
  grep -q "version=1.4 rate_limit=200" "$HM_TMP/g.txt" && break
  sleep 3
done
grep -q "edge-gateway version=1.4 rate_limit=200" "$HM_TMP/g.txt" || hm_fail "The gateway does not report version 1.4 with the new rate limit" "$HM_TMP/g.txt"
hm_pass "edge-gateway is on 1.4.0 with its history intact."
