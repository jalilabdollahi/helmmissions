#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed support-desk
hm_manifest_json support-desk | jq -e 'any(.[]; .kind=="ConfigMap" and .metadata.name=="desk-settings")' >/dev/null \
  || hm_fail "The release manifest does not contain the ConfigMap desk-settings"

hm_info "Checking who owns the ConfigMap..."
cm="$(kubectl get configmap desk-settings -n "$NS" -o json 2>/dev/null)" || hm_fail "ConfigMap desk-settings does not exist"
[ "$(echo "$cm" | jq -r '.metadata.annotations["meta.helm.sh/release-name"] // ""')" = "support-desk" ] \
  || hm_fail "ConfigMap desk-settings is not annotated as owned by release support-desk"
[ "$(echo "$cm" | jq -r '.metadata.annotations["meta.helm.sh/release-namespace"] // ""')" = "$NS" ] \
  || hm_fail "ConfigMap desk-settings has the wrong release-namespace annotation"
[ "$(echo "$cm" | jq -r '.metadata.labels["app.kubernetes.io/managed-by"] // ""')" = "Helm" ] \
  || hm_fail "ConfigMap desk-settings is missing the managed-by=Helm label"

hm_info "Checking the data comes from the chart..."
[ "$(echo "$cm" | jq -r '.data.MAX_OPEN_TICKETS // ""')" = "200" ] \
  || hm_fail "MAX_OPEN_TICKETS is '$(echo "$cm" | jq -r '.data.MAX_OPEN_TICKETS // ""')' — the chart's value should win"
[ "$(echo "$cm" | jq -r '.data.SLA_HOURS // ""')" = "8" ] || hm_fail "SLA_HOURS is missing or wrong in the live ConfigMap"

hm_info "Checking the workload..."
hm_wait_rollout deployment/support-desk "$NS" 90s

hm_pass "support-desk owns its ConfigMap and runs the chart's settings."
