#!/bin/bash
set -uo pipefail
source "$HM_LIB"

REL=report-worker
cd "$SANDBOX"

hm_info "Checking that the gate itself was left alone..."
[ -f ci/policy.sh ] || hm_fail "ci/policy.sh is missing from the workspace"
[ "$(hm_sha256 ci/policy.sh)" = "$(hm_sha256 "$LEVEL_DIR/broken/ci/policy.sh")" ] \
  || hm_fail "ci/policy.sh was modified — the gate belongs to the security team, fix the chart instead"
hm_ok "Gate script untouched"

hm_info "Running the policy gate against the workspace chart..."
bash ci/policy.sh >"$HM_TMP/gate.txt" 2>&1 || hm_fail "The policy gate still fails" "$HM_TMP/gate.txt"
hm_ok "The gate passes"

hm_info "Checking the deployed release..."
hm_require_deployed "$REL"
manifest="$(hm_manifest_json "$REL")"
echo "$manifest" | jq -r '.[]|select(.spec.template.spec.containers)|.metadata.name as $w|(.spec.template.spec.containers+(.spec.template.spec.initContainers//[]))[]
  | (.image|split("/")|last) as $r
  | select(($r|contains("@")|not) and (($r|contains(":")|not) or ($r|endswith(":latest"))))
  | "\($w)/\(.name): floating tag"' >"$HM_TMP/v.txt"
echo "$manifest" | jq -r '.[]|select(.spec.template.spec.containers)|.metadata.name as $w|(.spec.template.spec.containers+(.spec.template.spec.initContainers//[]))[]
  | select((.resources.limits.cpu//"")=="" or (.resources.limits.memory//"")=="") | "\($w)/\(.name): missing limits"' >>"$HM_TMP/v.txt"
echo "$manifest" | jq -r '.[]|select(.spec.template.spec.containers)|.metadata.name as $w|.spec.template.spec.containers[]
  | select(.readinessProbe==null or .livenessProbe==null) | "\($w)/\(.name): missing probes"' >>"$HM_TMP/v.txt"
[ ! -s "$HM_TMP/v.txt" ] || hm_fail "The deployed release still violates the policy (the gate passing locally is not enough)" "$HM_TMP/v.txt"
hm_ok "The live release satisfies every rule"

hm_wait_rollout "deployment/$REL" "$NS" 90s
ready="$(hm_jsonpath "deployment/$REL" '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 1 ] || hm_fail "Deployment $REL has no ready pod"
hm_pass "report-worker passes the gate and runs in the cluster."
