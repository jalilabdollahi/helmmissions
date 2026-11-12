#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_require_deployed status-page

hm_info "Checking the labels Helm manages..."
mv="$(hm_manifest_json status-page | jq -r '[.[] | select(.kind=="Deployment") | .spec.template.metadata.labels["app.version"]][0]')"
[ "$mv" = "1.10" ] || hm_fail "The release manifest labels the pods app.version=$mv, not 1.10"
dv="$(kubectl get deploy status-page -n "$NS" -o jsonpath='{.spec.template.metadata.labels.app\.version}')"
[ "$dv" = "1.10" ] || hm_fail "The live Deployment pod template has app.version=$dv, not 1.10"

hm_info "Checking the running pods..."
hm_wait_rollout deployment/status-page "$NS" 90s
bad="$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=status-page -o json | jq -r '[.items[] | select(.metadata.deletionTimestamp==null) | select(.metadata.labels["app.version"] != "1.10") | .metadata.name] | join(",")')"
[ -z "$bad" ] || hm_fail "Pods still carrying the wrong app.version label: $bad"
hm_pass "status-page pods are labelled app.version=1.10."
