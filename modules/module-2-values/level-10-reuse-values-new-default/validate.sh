#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_require_deployed notifier
chart="$(hm_release_chart notifier)"
[ "$chart" = "notifier-2.0.0" ] || hm_fail "Release notifier still runs chart '$chart' - the new chart has not been rolled out"

hm_info "Checking preserved and new values..."
[ "$(hm_user_values notifier | jq -r '.replicaCount // empty')" = "2" ] || hm_fail "The earlier override replicaCount=2 is gone from the release's user values"
[ "$(hm_all_values notifier | jq -r '.metrics.port // empty')" = "9102" ] || hm_fail "The release does not have the new chart's metrics.port default"
dep="$(hm_manifest_json notifier | jq -c '[.[] | select(.kind=="Deployment")][0]')"
[ "$(echo "$dep" | jq -r .spec.replicas)" = "2" ] || hm_fail "The deployed manifest has $(echo "$dep" | jq -r .spec.replicas) replicas instead of 2"
echo "$dep" | jq -e '[.spec.template.spec.containers[0].ports[].containerPort] | index(9102) != null' >/dev/null || hm_fail "The pod spec does not expose the metrics port 9102"

hm_wait_rollout deployment/notifier "$NS" 90s
ready="$(hm_jsonpath deployment/notifier '{.status.readyReplicas}')"
[ "${ready:-0}" = "2" ] || hm_fail "Only ${ready:-0}/2 replicas are ready"
hm_pass "notifier 2.0.0 is live with its tuned replica count and the new metrics default."
