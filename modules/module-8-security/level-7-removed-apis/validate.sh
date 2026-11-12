#!/bin/bash
set -uo pipefail
source "$HM_LIB"

REL=inventory
hm_require_deployed "$REL"
manifest="$(hm_manifest_json "$REL")"

hm_info "Checking the API versions in the release..."
served="$(kubectl api-versions 2>/dev/null)"
echo "$manifest" | jq -r '.[]|.apiVersion' | sort -u | while read -r v; do
  echo "$served" | grep -qx "$v" || { echo "$v"; }
done >"$HM_TMP/unserved.txt"
if [ -s "$HM_TMP/unserved.txt" ]; then hm_fail "The release uses API versions this cluster does not serve" "$HM_TMP/unserved.txt"; fi
hm_ok "Every API version in the release is served by the cluster"

hm_info "Checking the PodDisruptionBudget..."
pdb="$(kubectl get pdb "$REL" -n "$NS" -o json 2>/dev/null || true)"
[ -n "$pdb" ] || hm_fail "PodDisruptionBudget '$REL' does not exist in $NS"
[ "$(echo "$pdb" | jq -r '.spec.minAvailable')" = 1 ] || hm_fail "The PodDisruptionBudget does not keep minAvailable=1"
echo "$pdb" | jq -e '.spec.selector.matchLabels|length>0' >/dev/null || hm_fail "The PodDisruptionBudget selects no pods"
[ "$(echo "$pdb" | jq '.status.expectedPods // 0')" -ge 1 ] || hm_fail "The PodDisruptionBudget does not cover any running pod yet"

hm_info "Checking the HorizontalPodAutoscaler..."
hpa="$(kubectl get hpa.v2.autoscaling "$REL" -n "$NS" -o json 2>/dev/null || true)"
[ -n "$hpa" ] || hm_fail "HorizontalPodAutoscaler '$REL' does not exist (or cannot be read as autoscaling/v2)"
echo "$hpa" | jq -e '.spec.scaleTargetRef.kind=="Deployment" and .spec.scaleTargetRef.name=="inventory"' >/dev/null \
  || hm_fail "The HPA does not target the inventory Deployment"
echo "$hpa" | jq -e '.spec.minReplicas==2 and .spec.maxReplicas==4' >/dev/null || hm_fail "The HPA replica range is not 2 to 4"
echo "$hpa" | jq -e '[.spec.metrics[]?|select(.type=="Resource" and .resource.name=="cpu" and .resource.target.averageUtilization==70)]|length==1' >/dev/null \
  || hm_fail "The HPA does not scale on 70% average CPU utilization"
hm_ok "PDB and HPA are present with their original settings"

hm_info "Checking the workload..."
hm_wait_rollout "deployment/$REL" "$NS" 90s
ready="$(hm_jsonpath "deployment/$REL" '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment $REL has ${ready:-0}/2 ready pods"
hm_pass "inventory runs on supported APIs with its safety nets intact."
