#!/bin/bash
set -uo pipefail
source "$HM_LIB"

REL=status-page
hm_require_deployed "$REL"

hm_info "Checking the security context in the release..."
manifest="$(hm_manifest_json "$REL")"
echo "$manifest" | jq -e '[.[]|select(.kind=="Deployment")|.spec.template.spec as $p
  | $p.containers[] | (.securityContext.runAsNonRoot // $p.securityContext.runAsNonRoot // false)] | length>0 and all' >/dev/null \
  || hm_fail "A container in the release is no longer forced to run as non-root"
echo "$manifest" | jq -e '[.[]|select(.kind=="Deployment")|.spec.template.spec as $p
  | $p.containers[] | (.securityContext.runAsUser // $p.securityContext.runAsUser // 1)] | all(. != 0)' >/dev/null \
  || hm_fail "A container is configured to run as UID 0"
hm_ok "runAsNonRoot is enforced and no container is pinned to UID 0"

hm_info "Checking the workload..."
hm_wait_rollout "deployment/$REL" "$NS" 45s
ready="$(hm_jsonpath "deployment/$REL" '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment $REL has ${ready:-0}/2 ready pods"
pods="$(hm_pods_json app.kubernetes.io/instance=$REL)"
echo "$pods" | jq -e 'all(.[]; (.spec.securityContext.runAsNonRoot == true) or (.spec.containers | all(.securityContext.runAsNonRoot == true)))' >/dev/null \
  || hm_fail "A live pod does not have runAsNonRoot set"
pod="$(echo "$pods" | jq -r '[.[]|select(.status.phase=="Running")][0].metadata.name')"
uid="$(kubectl exec "$pod" -n "$NS" -- id -u 2>/dev/null || echo 0)"
[ "$uid" != "0" ] || hm_fail "The process in $pod runs as UID 0"
hm_ok "Pods are Ready and run as UID $uid"

[ "$(hm_endpoints_count $REL)" -ge 2 ] || hm_fail "Service $REL has fewer than 2 ready endpoints"
hm_http_check "http://$REL.$NS.svc/" "$NS" >"$HM_TMP/http.txt" || hm_fail "Service $REL does not answer HTTP"
hm_pass "The status page is up and nothing in it runs as root."
