#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed freight-quote

hm_info "Checking the workload..."
hm_wait_rollout deployment/freight-quote "$NS" 90s
ready="$(hm_jsonpath deployment/freight-quote '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment freight-quote has ${ready:-0}/2 ready pods"
hm_http_check http://freight-quote/quote >"$HM_TMP/q.txt" || hm_fail "GET /quote does not answer"
body="$(tail -n 1 "$HM_TMP/q.txt")"
echo "$body" | grep -q '"insurance":true' || hm_fail "GET /quote has no insurance quotes: $body"
echo "$body" | grep -q '"rate":42' || hm_fail "GET /quote returns the wrong rate: $body"
hm_ok "/quote answers correctly: $body"

hm_info "Checking how the release got here..."
desc="$(hm_release_description freight-quote)"
[ "$desc" = "Rollback to 4" ] || hm_fail "Newest revision is '$desc' - expected a rollback to the newest revision that behaved correctly"

hm_pass "freight-quote is back on the last good revision."
