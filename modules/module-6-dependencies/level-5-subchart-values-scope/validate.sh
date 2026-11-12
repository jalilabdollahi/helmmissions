#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed newsroom
[ "$(hm_release_revision newsroom)" -ge 3 ] || hm_fail "Release newsroom has not been upgraded since the engineer's attempt — the new settings were never rolled out"
manifest="$(hm_manifest_json newsroom)"
rz="$(echo "$manifest" | jq '[.[] | select(.kind=="Deployment" and .metadata.name=="newsroom-image-resizer")][0]')"
[ "$rz" != "null" ] || hm_fail "The release has no Deployment newsroom-image-resizer"

hm_info "Checking what the release asks for (helm manifest, not live edits)..."
rep="$(echo "$rz" | jq -r '.spec.replicas')"
env="$(echo "$rz" | jq -r '.spec.template.spec.containers[0].env | map(.name + "=" + .value) | join(",")')"
[ "$rep" = "3" ] || hm_fail "The release manifest asks for $rep resizer replicas, the photo desk wants 3"
[ "$env" = "MAX_WIDTH=800,JPEG_QUALITY=70" ] || hm_fail "Resizer settings in the release are '$env', expected MAX_WIDTH=800 and JPEG_QUALITY=70"

hm_info "Checking the running pods..."
hm_wait_rollout deployment/newsroom-image-resizer "$NS" 90s
ready="$(hm_jsonpath deployment/newsroom-image-resizer '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 3 ] || hm_fail "Deployment newsroom-image-resizer has ${ready:-0}/3 ready pods"
hm_wait_rollout deployment/newsroom-web "$NS" 90s

hm_pass "The resizer runs with the photo desk's settings."
