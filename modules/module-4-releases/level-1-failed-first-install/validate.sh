#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release state..."
hm_require_deployed invoice-api
chart="$(hm_release_chart invoice-api)"
[ "$chart" = "invoice-api-0.3.0" ] || hm_fail "Release invoice-api runs '$chart', expected the invoice-api chart from the workspace"

hm_info "Checking the objects Helm manages..."
svc_type="$(hm_jsonpath service/invoice-api '{.spec.type}')"
[ -n "$svc_type" ] || hm_fail "Service invoice-api does not exist"
hm_manifest_json invoice-api | jq -e '[.[]|select(.kind=="Service")]|length==1' >/dev/null \
  || hm_fail "The release manifest does not contain the Service — the objects are not managed by this release"

hm_info "Checking the workload..."
hm_wait_rollout deployment/invoice-api "$NS" 90s
ready="$(hm_jsonpath deployment/invoice-api '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment invoice-api has ${ready:-0}/2 ready pods"
[ "$(hm_endpoints_count invoice-api)" -ge 1 ] || hm_fail "Service invoice-api has no ready endpoints"

hm_pass "invoice-api is live and Helm finally agrees."
