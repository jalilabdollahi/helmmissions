#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed catalog
[ "$(hm_release_chart catalog)" = "catalog-seed-1.1.0" ] || hm_fail "Release catalog runs chart '$(hm_release_chart catalog)', expected catalog-seed-1.1.0"

hm_info "Checking the seed Job..."
jobs="$(hm_manifest_json catalog | jq -r '.[]|select(.kind=="Job")|.metadata.name')"
[ -n "$jobs" ] || hm_fail "The release manifest has no seed Job"
ok=0
for j in $jobs; do
  v="$(hm_jsonpath "job/$j" '{.spec.template.spec.containers[0].env[?(@.name=="SEED_VERSION")].value}')"
  [ "$v" = "2" ] || continue
  for _ in $(seq 1 30); do
    [ "$(hm_jsonpath "job/$j" '{.status.succeeded}')" = "1" ] && { ok=1; break; }
    sleep 2
  done
  [ "$ok" = 1 ] && break
done
[ "$ok" = 1 ] || hm_fail "No completed seed Job with SEED_VERSION=2 exists in the cluster - the new dataset was never seeded"
hm_ok "Seed Job with SEED_VERSION=2 completed"

hm_info "Checking the API..."
hm_wait_rollout deployment/catalog-api "$NS" 90s
[ "$(hm_endpoints_count catalog-api)" -ge 1 ] || hm_fail "Service catalog-api has no ready endpoints"

hm_pass "catalog 1.1.0 is deployed and the new dataset is seeded."
