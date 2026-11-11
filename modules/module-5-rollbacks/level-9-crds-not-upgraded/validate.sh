#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the CRD in the cluster..."
kubectl get crd snapshotpolicies.helmissions.io -o json >"$HM_TMP/crd.json" 2>/dev/null || hm_fail "CRD snapshotpolicies.helmissions.io does not exist"
jq -e '.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.retentionDays' "$HM_TMP/crd.json" >/dev/null \
  || hm_fail "The live CRD does not declare spec.retentionDays - the cluster still has the old schema"
hm_ok "CRD declares retentionDays"

hm_info "Checking the release..."
hm_require_deployed snapshots
[ "$(hm_release_chart snapshots)" = "snapshot-scheduler-2.0.0" ] || hm_fail "Release runs chart '$(hm_release_chart snapshots)', expected snapshot-scheduler-2.0.0"

hm_info "Checking the SnapshotPolicy..."
r="$(hm_jsonpath snapshotpolicy/nightly '{.spec.retentionDays}')"
[ "$r" = "30" ] || hm_fail "SnapshotPolicy nightly has retentionDays='${r:-<unset>}', expected 30"
hm_wait_rollout deployment/snapshots-controller "$NS" 90s

hm_pass "CRD, policy and release agree on retentionDays."
