#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/ingest"
[ -f "$CHART/Chart.yaml" ] || hm_fail "ingest/Chart.yaml is missing from the workspace"
portarg() { jq -r '[.[] | select(.kind=="Deployment") | .spec.template.spec.containers[0].args[]? | select(startswith("--port="))] | first // empty'; }
want="$(hm_yaml_get "$CHART/values.yaml" port | jq -r 'tostring')"

hm_info "Rendering the chart with values from files..."
hm_render_json "$CHART" >"$HM_TMP/a.json" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
a="$(portarg <"$HM_TMP/a.json")"
[ "$a" = "--port=$want" ] || hm_fail "With the chart's own values the port argument is '$a', expected '--port=$want'"
printf 'port: 9100\n' >"$HM_TMP/alt-values.yaml"
hm_render_json "$CHART" -f "$HM_TMP/alt-values.yaml" >"$HM_TMP/b.json" || hm_fail "helm template fails with another values file"
b="$(portarg <"$HM_TMP/b.json")"
[ "$b" = "--port=9100" ] || hm_fail "With 'port: 9100' in a values file the argument is '$b', expected '--port=9100'"
hm_ok "The port argument is a clean number"

hm_info "Checking the release..."
hm_require_deployed ingest
rev="$(hm_release_revision ingest)"
[ "${rev:-0}" -ge 2 ] || hm_fail "Release ingest is still at revision ${rev:-?} - the fixed chart was never deployed"
[ "$(hm_manifest_json ingest | portarg)" = "--port=$want" ] || hm_fail "The release manifest still has '$(hm_manifest_json ingest | portarg)'"
hm_wait_rollout deployment/ingest "$NS" 90s
live="$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=ingest -o json | jq -r '[.items[] | select(.metadata.deletionTimestamp==null)] | first | .spec.containers[0].args[0]')"
[ "$live" = "--port=$want" ] || hm_fail "The running pod has argument '$live'"
[ "$(hm_endpoints_count ingest)" -ge 1 ] || hm_fail "Service ingest has no ready endpoints"

hm_pass "ingest is listening on a real port number."
