#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/parcel-tracker"

hm_info "Checking what Helm deployed..."
hm_require_deployed parcel-tracker
kinds="$(hm_manifest_json parcel-tracker | jq -r '[.[].kind] | join(" ")')"
echo "$kinds" | grep -qw Deployment || hm_fail "The release manifest contains no Deployment (kinds: '${kinds:-none}') - Helm deployed an empty release"
echo "$kinds" | grep -qw Service || hm_fail "The release manifest contains no Service (kinds: '${kinds:-none}')"
hm_ok "Release manifest contains: $kinds"

hm_info "Checking the chart layout..."
[ -d "$CHART/templates" ] || hm_fail "The chart has no 'templates' directory - the chart layout is not what Helm expects"
[ ! -d "$CHART/template" ] || hm_fail "A stray 'template' directory is still in the chart"
ls "$CHART"/templates/*.yaml >/dev/null 2>&1 || hm_fail "templates/ contains no manifests"
hm_ok "Chart layout is correct"

hm_info "Checking the workload..."
hm_wait_rollout deployment/parcel-tracker "$NS" 90s
[ "$(hm_endpoints_count parcel-tracker)" -ge 1 ] || hm_fail "Service parcel-tracker has no ready endpoints"

hm_pass "parcel-tracker is live - Helm finally found its templates."
