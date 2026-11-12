#!/bin/bash
set -uo pipefail
source "$HM_LIB"

REL=flag-sync
hm_require_deployed "$REL"

hm_info "Reading the RBAC shipped by the release..."
manifest="$(hm_manifest_json "$REL")"
sa="$(hm_jsonpath deployment/$REL '{.spec.template.spec.serviceAccountName}')"
[ -n "$sa" ] || hm_fail "The Deployment does not use a dedicated ServiceAccount"
[ "$sa" != "default" ] || hm_fail "The workload runs as the default ServiceAccount"

echo "$manifest" | jq -e '[.[]|select(.kind=="Role" or .kind=="ClusterRole")|.rules[]?|(.verbs+.resources+.apiGroups)[]|select(.=="*")]|length==0' >/dev/null \
  || hm_fail "A rule shipped by the release uses a wildcard (*)"
echo "$manifest" | jq -e '[.[]|select(.kind=="ClusterRoleBinding")]|length==0' >/dev/null \
  || hm_fail "The release creates a cluster-wide binding — this workload only needs its own namespace"
hm_ok "RBAC in the release has no wildcards or cluster-wide bindings"

hm_info "Asking the API server what the ServiceAccount may do..."
who="system:serviceaccount:$NS:$sa"
can() { kubectl auth can-i "$@" --as="$who" 2>/dev/null; }
[ "$(can list configmaps -n "$NS")" = yes ] || hm_fail "$sa still cannot list configmaps in $NS"
[ "$(can list pods -n "$NS")" = yes ] || hm_fail "$sa can no longer list pods in $NS (the syncer needs it)"
for denied in "create configmaps" "update configmaps" "patch configmaps" "delete configmaps" "list secrets" "get secrets" "create pods" "delete pods" "create deployments.apps" "create roles.rbac.authorization.k8s.io"; do
  [ "$(can $denied -n "$NS")" = no ] || hm_fail "$sa is allowed to '$denied' — more than a read-only syncer needs"
done
for other in kube-system default; do
  [ "$(can list configmaps -n "$other")" = no ] || hm_fail "$sa can read configmaps in namespace $other"
done
[ "$(can list nodes)" = no ] || hm_fail "$sa can list nodes cluster-wide"
[ "$(can '*' '*' -n "$NS")" = no ] || hm_fail "$sa can do everything in $NS"
echo "$manifest" | jq -e '[.[]|select(.kind=="Role")|.rules[]?|select(((.resources//[])|index("configmaps")) and ((.verbs//[])|index("list")))]|length>0' >/dev/null \
  || hm_fail "The permissions that work today are not coming from the release's own RBAC objects — the next helm upgrade would take them away"
hm_ok "Permissions are exactly read-only on pods and ConfigMaps in $NS"

hm_info "Checking the workload..."
hm_wait_rollout "deployment/$REL" "$NS" 90s
hm_wait_pods_ready app.kubernetes.io/instance=$REL "$NS" 60s
logs="$(kubectl logs deploy/$REL -n "$NS" --tail=3 2>/dev/null || true)"
echo "$logs" | tail -1 | grep -q "pods -> 200, list configmaps -> 200" || { echo "$logs" >"$HM_TMP/logs.txt"; hm_fail "The pod log does not report 200 for both calls" "$HM_TMP/logs.txt"; }

hm_pass "flag-sync can read what it needs — and nothing else."
