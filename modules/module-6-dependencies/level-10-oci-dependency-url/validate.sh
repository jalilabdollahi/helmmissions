#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/booking"
GOOD="oci://$HM_REGISTRY/m6-oci-dependency-url/charts"

hm_info "Checking the dependency was resolved from the registry..."
lrepo="$(hm_yaml_get "$CHART/Chart.lock" dependencies.0.repository | jq -r '. // ""')"
lver="$(hm_yaml_get "$CHART/Chart.lock" dependencies.0.version | jq -r '. // ""')"
[ -n "$lver" ] || hm_fail "There is no Chart.lock entry for seat-cache — the dependency was never resolved"
repo="$(hm_yaml_get "$CHART/Chart.yaml" dependencies.0.repository | jq -r '. // ""')"
[ "${repo%/}" = "$GOOD" ] || hm_fail "Chart.yaml points the dependency at '$repo', which is not the registry path the platform team publishes charts under"
[ "${lrepo%/}" = "$GOOD" ] || hm_fail "Chart.lock records repository '$lrepo' — it has to be regenerated after fixing Chart.yaml"
[ -f "$CHART/charts/seat-cache-$lver.tgz" ] || hm_fail "charts/ does not contain seat-cache-$lver.tgz"
hm_ok "seat-cache $lver pulled from $GOOD"

hm_info "Checking the release..."
hm_require_deployed booking
chart="$(hm_release_chart booking)"
[ "$chart" = "booking-2.3.0" ] || hm_fail "Release booking runs chart '$chart', expected booking-2.3.0"
v="$(hm_manifest_json booking | jq -r '[.[] | select(.kind=="Deployment" and .metadata.name=="booking-seat-cache")][0].metadata.labels["helm.sh/chart"] // ""')"
[ "$v" = "seat-cache-$lver" ] || hm_fail "The release contains '${v:-no seat cache}', expected seat-cache-$lver"
hm_wait_rollout deployment/booking-api "$NS" 90s
hm_wait_rollout deployment/booking-seat-cache "$NS" 90s
hold="$(hm_jsonpath deployment/booking-seat-cache '{.spec.template.spec.containers[0].env[?(@.name=="HOLD_SECONDS")].value}')"
[ "$hold" = "120" ] || hm_fail "HOLD_SECONDS is '$hold' (booking/values.yaml asks for 120)"
hm_pass "booking is live with seat-cache from the OCI registry."
