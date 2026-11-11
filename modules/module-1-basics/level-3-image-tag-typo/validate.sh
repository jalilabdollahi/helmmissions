#!/bin/bash
set -uo pipefail
source "$HM_LIB"

WANT_IMAGE="nginx:1.27-alpine"

hm_info "Checking the chart in your workspace..."
tag="$(hm_yaml_get "$SANDBOX/ledger-api/values.yaml" image.tag)"
[ "$tag" = '"1.27-alpine"' ] || hm_fail "ledger-api/values.yaml still has image.tag $tag - the source of truth is not fixed"
hm_ok "values.yaml points at a real tag"

hm_info "Checking the release..."
hm_require_deployed ledger-api
img="$(hm_manifest_json ledger-api | jq -r '[.[] | select(.kind=="Deployment")][0].spec.template.spec.containers[0].image')"
[ "$img" = "$WANT_IMAGE" ] || hm_fail "Helm's record of the release still says image '$img' - a manual patch is not a release"
hm_ok "Release manifest uses $img"

hm_info "Checking the pods..."
hm_wait_rollout deployment/ledger-api "$NS" 90s
ready="$(hm_jsonpath deployment/ledger-api '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment ledger-api has ${ready:-0}/2 ready pods"
bad="$(kubectl get pods -n "$NS" -l app=ledger-api -o json | jq -r --arg i "$WANT_IMAGE" '[.items[] | select(.status.phase=="Running") | .spec.containers[0].image | select(. != $i)] | length')"
[ "$bad" = "0" ] || hm_fail "Some running pods still use a different image"

hm_pass "ledger-api is serving again."
