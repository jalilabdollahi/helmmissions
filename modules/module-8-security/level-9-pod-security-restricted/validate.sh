#!/bin/bash
set -uo pipefail
source "$HM_LIB"

REL=audit-gateway
hm_info "Checking the namespace policy..."
lvl="$(kubectl get namespace "$NS" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)"
[ "$lvl" = restricted ] || hm_fail "Namespace $NS enforces '${lvl:-nothing}' instead of 'restricted' — the policy was weakened"
ver="$(kubectl get namespace "$NS" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce-version}' 2>/dev/null)"
case "${ver:-latest}" in latest|v1.*) ;; *) hm_fail "The enforce-version label was pinned to '$ver'";; esac
hm_ok "Namespace still enforces restricted"

hm_require_deployed "$REL"
hm_info "Checking the workload..."
hm_wait_rollout "deployment/$REL" "$NS" 45s
ready="$(hm_jsonpath "deployment/$REL" '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 1 ] || hm_fail "Deployment $REL has no ready pod"

hm_info "Checking every container's security context..."
pods="$(hm_pods_json app.kubernetes.io/instance=$REL)"
echo "$pods" | jq -r '.[]|select(.status.phase=="Running")|.spec as $s
  | ($s.containers + ($s.initContainers//[]))[]
  | select(
      (.securityContext.allowPrivilegeEscalation != false)
      or (((.securityContext.capabilities.drop // []) | index("ALL")) == null)
      or ((.securityContext.runAsNonRoot // $s.securityContext.runAsNonRoot) != true)
      or ((.securityContext.seccompProfile.type // $s.securityContext.seccompProfile.type) != "RuntimeDefault"))
  | "container \(.name) does not meet the restricted profile"' >"$HM_TMP/sec.txt"
[ ! -s "$HM_TMP/sec.txt" ] || hm_fail "The running pod is not hardened as required" "$HM_TMP/sec.txt"
echo "$pods" | jq -e '[.[]|select(.status.phase=="Running")]|length>=1' >/dev/null || hm_fail "No running pod found"
hm_ok "All containers (init included) are hardened"
hm_pass "audit-gateway runs under the restricted Pod Security level."
