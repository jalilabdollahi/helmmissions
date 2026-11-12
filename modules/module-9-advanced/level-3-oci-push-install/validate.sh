#!/bin/bash
set -uo pipefail
source "$HM_LIB"

BASE="$(cat "$SANDBOX/.hm-registry-base" 2>/dev/null)"
[ -n "$BASE" ] || hm_fail "Workspace marker .hm-registry-base is missing — reset the mission"
REF="oci://$HM_REGISTRY/$BASE/charts/payments-gateway"
CHART="$SANDBOX/payments-gateway"

hm_info "Checking the chart in the workspace..."
[ "$(hm_yaml_get "$CHART/Chart.yaml" version | jq -r '.')" = "0.3.0" ] || hm_fail "The workspace chart is not version 0.3.0 any more"

hm_info "Looking for payments-gateway 0.3.0 at the registry convention..."
helm show chart "$REF" --version 0.3.0 --plain-http >"$HM_TMP/show.txt" 2>&1 \
  || hm_fail "Nothing is published at the registry reference $REF with tag 0.3.0" "$HM_TMP/show.txt"
grep -q '^version: 0.3.0' "$HM_TMP/show.txt" || hm_fail "The artifact at $REF:0.3.0 is not chart version 0.3.0"
mkdir -p "$HM_TMP/pull"
helm pull "$REF" --version 0.3.0 --plain-http --untar --untardir "$HM_TMP/pull" >/dev/null 2>"$HM_TMP/pull-err.txt" \
  || hm_fail "Could not pull the published chart" "$HM_TMP/pull-err.txt"
diff -r -x Chart.yaml "$HM_TMP/pull/payments-gateway" "$CHART" >"$HM_TMP/diff.txt" 2>&1 \
  || hm_fail "The published 0.3.0 differs from the chart in the workspace" "$HM_TMP/diff.txt"
for k in name version appVersion; do
  [ "$(hm_yaml_get "$HM_TMP/pull/payments-gateway/Chart.yaml" $k)" = "$(hm_yaml_get "$CHART/Chart.yaml" $k)" ] \
    || hm_fail "The published Chart.yaml differs from the workspace chart ($k)"
done
hm_ok "0.3.0 is published at the convention and matches the workspace"

hm_info "Checking the release..."
hm_require_deployed payments-gateway
chart="$(hm_release_chart payments-gateway)"
[ "$chart" = "payments-gateway-0.3.0" ] || hm_fail "Release payments-gateway runs chart '$chart', expected payments-gateway-0.3.0"
[ "$(hm_release_revision payments-gateway)" -ge 2 ] || hm_fail "Release payments-gateway was not upgraded"
hm_wait_rollout deployment/payments-gateway "$NS" 90s
ready="$(hm_jsonpath deployment/payments-gateway '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment payments-gateway has ${ready:-0}/2 ready pods"
ttl="$(hm_jsonpath deployment/payments-gateway '{.spec.template.spec.containers[0].env[0].value}')"
[ "$ttl" = "300" ] || hm_fail "The running pods use IDEMPOTENCY_TTL_SECONDS=$ttl — they are not running the 0.3.0 values"
hm_pass "payments-gateway 0.3.0 is shipped through the registry."
