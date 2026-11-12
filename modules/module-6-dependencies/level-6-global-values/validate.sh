#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed telemetry
[ "$(hm_release_revision telemetry)" -ge 3 ] || hm_fail "Release telemetry has not been upgraded since the region attempt — nothing was rolled out"
manifest="$(hm_manifest_json telemetry)"

hm_info "Checking that every component carries the region (from the release, not from live edits)..."
for d in gateway collector exporter; do
  dep="telemetry-$d"
  region="$(echo "$manifest" | jq -r --arg d "$dep" '[.[] | select(.kind=="Deployment" and .metadata.name==$d)][0].spec.template.spec.containers[0].env // [] | map(select(.name=="REGION") | .value) | first // ""')"
  [ "$region" = "eu-west-1" ] || hm_fail "Deployment $dep is released with REGION='${region:-<missing>}', expected eu-west-1"
  envn="$(echo "$manifest" | jq -r --arg d "$dep" '[.[] | select(.kind=="Deployment" and .metadata.name==$d)][0].spec.template.spec.containers[0].env // [] | map(select(.name=="ENVIRONMENT") | .value) | first // ""')"
  [ "$envn" = "production" ] || hm_fail "Deployment $dep lost ENVIRONMENT=production (got '$envn')"
done

hm_info "Checking the running pods..."
for d in gateway collector exporter; do
  hm_wait_rollout "deployment/telemetry-$d" "$NS" 90s
  live="$(hm_jsonpath "deployment/telemetry-$d" '{.spec.template.spec.containers[0].env[?(@.name=="REGION")].value}')"
  [ "$live" = "eu-west-1" ] || hm_fail "Live Deployment telemetry-$d reports REGION='$live'"
done

hm_pass "The whole telemetry stack reports eu-west-1."
