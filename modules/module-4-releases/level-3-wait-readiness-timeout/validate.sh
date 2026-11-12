#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed docs-portal
hist="$(hm_history_json docs-portal)"
latest="$(echo "$hist" | jq -r '.[-1].revision')"
[ "$latest" -ge 3 ] || hm_fail "Release is still on revision $latest — the failed upgrade was never replaced"
case "$(echo "$hist" | jq -r '.[-1].description')" in
  Rollback*) hm_fail "The newest revision is a rollback — chart 2.1 is not what is running" ;;
esac
[ "$(hm_release_chart docs-portal)" = "docs-portal-2.1.0" ] \
  || hm_fail "Release runs '$(hm_release_chart docs-portal)', expected docs-portal-2.1.0"

hm_info "Checking the workload..."
hm_wait_rollout deployment/docs-portal "$NS" 90s
spec="$(hm_jsonpath deployment/docs-portal '{.spec.replicas}')"
ready="$(hm_jsonpath deployment/docs-portal '{.status.readyReplicas}')"
[ "${spec:-0}" -ge 2 ] && [ "${ready:-0}" -ge 2 ] || hm_fail "Deployment docs-portal has ${ready:-0}/${spec:-?} ready replicas, expected 2/2"
probe="$(kubectl get deployment docs-portal -n "$NS" -o json | jq -c '.spec.template.spec.containers[0].readinessProbe // empty')"
[ -n "$probe" ] || hm_fail "The container has no readiness probe any more — the point of 2.1 was to have one"
[ "$(hm_endpoints_count docs-portal)" -ge 2 ] || hm_fail "Service docs-portal has fewer than 2 ready endpoints"

hm_pass "docs-portal 2.1 is rolled out and ready."
