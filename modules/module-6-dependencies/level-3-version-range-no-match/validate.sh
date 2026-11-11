#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/searchdesk"

hm_info "Checking the dependency declaration and lock..."
hm_yaml_get "$CHART/Chart.yaml" dependencies | jq -e 'any(.[]; .name=="redis-lite")' >/dev/null \
  || hm_fail "searchdesk/Chart.yaml no longer declares the redis-lite dependency"
locked="$(hm_yaml_get "$CHART/Chart.lock" dependencies.0.version | jq -r '. // ""')"
[ -n "$locked" ] || hm_fail "There is no Chart.lock entry for redis-lite — the dependency was never resolved"
echo "$locked" | grep -Eq '^1\.2\.[0-9]+$' || hm_fail "Chart.lock resolved redis-lite to '$locked', which the repository does not serve as a 1.2.x release"
[ -f "$CHART/charts/redis-lite-$locked.tgz" ] || hm_fail "charts/ does not contain the redis-lite $locked tarball that Chart.lock names"
hm_ok "redis-lite resolves to $locked"

hm_info "Checking the release..."
hm_require_deployed searchdesk
chart="$(hm_release_chart searchdesk)"
[ "$chart" = "searchdesk-1.0.0" ] || hm_fail "Release searchdesk runs chart '$chart', expected searchdesk-1.0.0"
dbver="$(hm_manifest_json searchdesk | jq -r '[.[] | select(.kind=="Deployment" and .metadata.name=="searchdesk-redis-lite")][0].metadata.labels["helm.sh/chart"] // ""')"
[ "$dbver" = "redis-lite-$locked" ] || hm_fail "The release contains '${dbver:-no cache}', expected redis-lite-$locked from the lock"

hm_info "Checking the workloads..."
hm_wait_rollout deployment/searchdesk "$NS" 90s
hm_wait_rollout deployment/searchdesk-redis-lite "$NS" 90s
mk="$(hm_jsonpath deployment/searchdesk-redis-lite '{.spec.template.spec.containers[0].env[?(@.name=="MAX_KEYS")].value}')"
[ "$mk" = "5000" ] || hm_fail "MAX_KEYS is '$mk' (searchdesk/values.yaml asks for 5000)"

hm_pass "searchdesk is live with a resolvable redis-lite."
