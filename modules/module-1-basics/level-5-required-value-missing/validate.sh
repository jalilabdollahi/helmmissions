#!/bin/bash
set -uo pipefail
source "$HM_LIB"

HOST="docs.staging.helmissions.local"
CHART="$SANDBOX/docs-site"

hm_info "Checking the release..."
hm_require_deployed docs-site
chart="$(hm_release_chart docs-site)"
case "$chart" in docs-site-*) ;; *) hm_fail "Release docs-site runs chart '$chart'" ;; esac

hm_info "Checking the Ingress..."
live="$(hm_jsonpath ingress/docs-site '{.spec.rules[0].host}')"
[ -n "$live" ] || hm_fail "Ingress docs-site does not exist or has no host"
[ "$live" = "$HOST" ] || hm_fail "Ingress host is '$live', expected '$HOST'"
uv="$(hm_user_values docs-site | jq -r '.ingressHost // empty')"
[ "$uv" = "$HOST" ] || hm_fail "The release has no user-supplied ingressHost '$HOST' (found '${uv:-none}')"
hm_ok "Ingress host is $live"

hm_info "Checking where the setting lives..."
dflt="$(hm_yaml_get "$CHART/values.yaml" ingressHost)"
[ "$dflt" = '""' ] || [ "$dflt" = 'null' ] \
  || hm_fail "The chart's own values.yaml now hardcodes ingressHost ($dflt) - the chart is shared, keep its defaults generic"
found=0
while IFS= read -r f; do
  [ "$(hm_yaml_get "$f" ingressHost)" = "\"$HOST\"" ] && found=1
done < <(find "$SANDBOX" -path "$CHART" -prune -o -type f \( -name '*.yaml' -o -name '*.yml' \) -print)
[ "$found" = 1 ] || hm_fail "No values file in the workspace (outside the chart) defines ingressHost - the staging setting is not kept anywhere"
hm_ok "Staging host is kept in a values file next to the chart"

hm_wait_rollout deployment/docs-site "$NS" 90s
hm_pass "docs-site is deployed for staging."
