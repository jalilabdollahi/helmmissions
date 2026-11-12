#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/smtp-relay"
[ -f "$CHART/Chart.yaml" ] || hm_fail "smtp-relay/Chart.yaml is missing from the workspace"
portenv() { jq -c '[.[] | select(.kind=="Deployment") | .spec.template.spec.containers[0].env[]? | select(.name=="WHOAMI_PORT_NUMBER") | .value] | first'; }

hm_info "Rendering the chart from the workspace..."
hm_render_json "$CHART" --set listenPort=2626 >"$HM_TMP/r.json" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
v="$(portenv <"$HM_TMP/r.json")"
[ "$v" = '"2626"' ] || hm_fail "With listenPort=2626 the variable WHOAMI_PORT_NUMBER renders as $v - it must be the string \"2626\""
hm_ok "WHOAMI_PORT_NUMBER follows listenPort and is a string"

hm_info "Checking the release..."
hm_require_deployed relay
[ "$(hm_release_chart relay)" = "smtp-relay-1.1.0" ] || hm_fail "Release relay was not deployed from the smtp-relay chart"
want="$(hm_yaml_get "$CHART/values.yaml" listenPort | jq -r 'tostring')"
[ "$(hm_manifest_json relay | portenv)" = "\"$want\"" ] || hm_fail "The release manifest does not carry WHOAMI_PORT_NUMBER=$want"
hm_wait_rollout deployment/relay "$NS" 90s
[ "$(hm_endpoints_count relay)" -ge 1 ] || hm_fail "Service relay has no ready endpoints"
live="$(kubectl get pods -n "$NS" -l app=smtp-relay -o json | jq -r '.items[0].spec.containers[0].env[] | select(.name=="WHOAMI_PORT_NUMBER") | .value')"
[ "$live" = "$want" ] || hm_fail "The running pod has WHOAMI_PORT_NUMBER='$live'"

hm_pass "relay is listening on its configured port."
