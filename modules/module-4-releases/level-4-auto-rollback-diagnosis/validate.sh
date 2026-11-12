#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release history..."
hm_require_deployed telemetry-gw
hist="$(hm_history_json telemetry-gw)"
latest="$(echo "$hist" | jq -r '.[-1].revision')"
[ "$latest" -ge 4 ] || hm_fail "The newest revision is still $latest — the 0.5 upgrade has not been deployed yet"
case "$(echo "$hist" | jq -r '.[-1].description')" in
  Rollback*) hm_fail "The newest revision is a rollback — the release is back on the old configuration" ;;
esac
[ "$(hm_release_chart telemetry-gw)" = "telemetry-gw-0.5.0" ] \
  || hm_fail "Release runs '$(hm_release_chart telemetry-gw)', expected telemetry-gw-0.5.0"

hm_info "Checking the 0.5 changes are live..."
hm_wait_rollout deployment/telemetry-gw "$NS" 90s
ready="$(hm_jsonpath deployment/telemetry-gw '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 3 ] || hm_fail "Deployment telemetry-gw has ${ready:-0}/3 ready pods"
kubectl get deployment telemetry-gw -n "$NS" -o json | jq -e '.spec.template.spec.containers[0].env // [] | any(.[]; .name=="SAMPLE_RATE" and .value=="0.25")' >/dev/null \
  || hm_fail "SAMPLE_RATE=0.25 is not set on the live Deployment"
sched="$(hm_jsonpath cronjob/telemetry-gw-usage-report '{.spec.schedule}')"
[ -n "$sched" ] || hm_fail "The usage-report CronJob does not exist"
[ "$(echo "$sched" | wc -w | tr -d ' ')" = "5" ] || hm_fail "CronJob schedule '$sched' is not a valid cron expression"

hm_pass "telemetry-gw 0.5 is deployed for real this time."
