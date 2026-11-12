#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/inventory"

hm_info "Checking the chart declares two instances of the subchart..."
hm_yaml_get "$CHART/Chart.yaml" dependencies | jq -e '[.[] | select(.name=="kvstore")] | length >= 2' >/dev/null \
  || hm_fail "inventory/Chart.yaml must run the kvstore subchart twice (a read-write primary and a read-only replica)"

hm_info "Checking the release..."
hm_require_deployed inventory
chart="$(hm_release_chart inventory)"
[ "$chart" = "inventory-1.4.0" ] || hm_fail "Release inventory runs chart '$chart', expected inventory-1.4.0"
manifest="$(hm_manifest_json inventory)"
for inst in primary:readwrite:64 replica:readonly:32; do
  IFS=: read -r name mode mem <<<"$inst"
  dep="inventory-$name"
  echo "$manifest" | jq -e --arg d "$dep" 'any(.[]; .kind=="Deployment" and .metadata.name==$d)' >/dev/null \
    || hm_fail "The release has no Deployment $dep — the $name store was not deployed as its own instance"
  got="$(echo "$manifest" | jq -r --arg d "$dep" '[.[] | select(.kind=="Deployment" and .metadata.name==$d)][0].spec.template.spec.containers[0].env | map(select(.name=="KV_MODE" or .name=="KV_MAX_MEMORY_MB") | .value) | join("/")')"
  [ "$got" = "$mode/$mem" ] || hm_fail "Deployment $dep runs mode/maxMemoryMB '$got', expected '$mode/$mem' (see inventory/values.yaml)"
  hm_wait_rollout "deployment/$dep" "$NS" 90s
done
hm_wait_rollout deployment/inventory-api "$NS" 90s
for s in inventory-primary inventory-replica; do
  [ "$(hm_endpoints_count "$s")" -ge 1 ] || hm_fail "Service $s has no ready endpoints"
done

hm_pass "inventory runs its primary and replica stores side by side."
