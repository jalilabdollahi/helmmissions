#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed quotes-api
desc="$(hm_release_description quotes-api)"
case "$desc" in
  Rollback*) hm_ok "Newest revision is a rollback record ($desc)" ;;
  *) hm_fail "The newest revision's description is '$desc' - the release was moved forward, not returned to an earlier revision" ;;
esac

hm_info "Checking the workload..."
img="$(hm_jsonpath deployment/quotes-api '{.spec.template.spec.containers[0].image}')"
[ "$img" = "traefik/whoami:v1.10" ] || hm_fail "Deployment quotes-api runs image '$img', not the image from before the bad upgrade"
hm_wait_rollout deployment/quotes-api "$NS" 90s
[ "$(hm_endpoints_count quotes-api)" -ge 1 ] || hm_fail "Service quotes-api has no ready endpoints"
hm_http_check http://quotes-api >"$HM_TMP/body.txt" || hm_fail "http://quotes-api does not answer"

hm_pass "quotes-api is back on its last good revision."
