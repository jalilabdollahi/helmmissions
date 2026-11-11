#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/tradedesk"
MON='metrics-agent|log-shipper|trace-collector'

hm_info "Checking all three monitoring components are still declared..."
for d in metrics-agent log-shipper trace-collector; do
  hm_yaml_get "$CHART/Chart.yaml" dependencies | jq -e --arg d "$d" 'any(.[]; .name==$d)' >/dev/null \
    || hm_fail "tradedesk/Chart.yaml no longer declares $d"
done

hm_info "Checking the toggle behaves as one group..."
n_off="$(hm_render_json "$CHART" | jq --arg re "$MON" '[.[] | select((.metadata.name // "") | test($re))] | length')"
[ "${n_off:-9}" = "0" ] || hm_fail "With the default values (tags.monitoring: false) the chart still renders $n_off monitoring object(s)"
got="$(hm_render_json "$CHART" --set tags.monitoring=true | jq -r '[.[] | select(.kind=="Deployment") | .metadata.name | select(test("metrics-agent|log-shipper|trace-collector"))] | sort | join(",")')"
[ "$got" = "hm-render-log-shipper,hm-render-metrics-agent,hm-render-trace-collector" ] \
  || hm_fail "With tags.monitoring=true the chart renders [$got]; the whole monitoring group (metrics, logs, traces) must come back together"
hm_ok "tags.monitoring switches the three components together"

hm_info "Checking the release..."
hm_require_deployed tradedesk
[ "$(hm_release_revision tradedesk)" -ge 2 ] || hm_fail "Release tradedesk is still on its first revision — nothing was rolled out"
hm_manifest_json tradedesk | jq -e --arg re "$MON" 'any(.[]; (.metadata.name // "") | test($re))' >/dev/null \
  && hm_fail "The tradedesk release still contains monitoring objects (helm get manifest tradedesk)"
for d in metrics-agent log-shipper trace-collector; do
  kubectl get deployment "tradedesk-$d" -n "$NS" >/dev/null 2>&1 && hm_fail "Deployment tradedesk-$d is still running"
done
hm_wait_rollout deployment/tradedesk-api "$NS" 90s
hm_pass "The monitoring stack is off as a group and can be switched back on as a group."
