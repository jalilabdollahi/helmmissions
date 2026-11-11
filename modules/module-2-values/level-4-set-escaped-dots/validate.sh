#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_require_deployed telemetry-agent

hm_info "Checking the pod template annotations..."
ann="$(kubectl get deploy telemetry-agent -n "$NS" -o json | jq -c '.spec.template.metadata.annotations // {}')"
echo "$ann" | jq -e 'has("prometheus.io/scrape")' >/dev/null || hm_fail "The pod template has no annotation named prometheus.io/scrape (annotations: $ann)"
[ "$(echo "$ann" | jq -r '.["prometheus.io/scrape"]')" = "true" ] || hm_fail "prometheus.io/scrape is not \"true\" (annotations: $ann)"
[ "$(echo "$ann" | jq -r '.["prometheus.io/port"] // empty')" = "9100" ] || hm_fail "prometheus.io/port is not \"9100\" (annotations: $ann)"
echo "$ann" | jq -e 'keys | map(select(startswith("prometheus.io/") | not)) | length == 0' >/dev/null || hm_fail "Unexpected leftover annotation(s) on the pod template: $ann"
hm_manifest_json telemetry-agent | jq -e '[.[] | select(.kind=="Deployment") | .spec.template.metadata.annotations | has("prometheus.io/scrape")] | all' >/dev/null \
  || hm_fail "The release manifest does not carry the annotation - it was changed outside Helm"

hm_wait_rollout deployment/telemetry-agent "$NS" 90s
pa="$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=telemetry-agent -o json | jq -r '[.items[] | select(.metadata.deletionTimestamp==null) | .metadata.annotations["prometheus.io/scrape"]] | all(. == "true")')"
[ "$pa" = "true" ] || hm_fail "Running pods do not carry prometheus.io/scrape=true yet"
hm_pass "Prometheus can discover telemetry-agent."
