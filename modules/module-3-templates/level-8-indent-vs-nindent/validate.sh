#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/ledger-recon"
[ -f "$CHART/Chart.yaml" ] || hm_fail "ledger-recon/Chart.yaml is missing from the workspace"
labels() { jq -c --arg k "$1" '[.[] | select(.kind==$k) | .metadata.labels] | first // {}'; }

hm_info "Rendering the chart from the workspace..."
helm lint "$CHART" >"$HM_TMP/lint.txt" 2>&1 || hm_fail "helm lint reports errors" "$HM_TMP/lint.txt"
hm_render_json "$CHART" >"$HM_TMP/r.json" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
[ "$(jq '[.[] | select(.kind=="CronJob")] | length' "$HM_TMP/r.json")" = "1" ] || hm_fail "The chart does not render a CronJob"
cl="$(labels CronJob <"$HM_TMP/r.json")"; ml="$(labels ConfigMap <"$HM_TMP/r.json")"
[ "$(echo "$cl" | jq -S -c .)" = "$(echo "$ml" | jq -S -c .)" ] || hm_fail "CronJob labels ($cl) differ from the ConfigMap labels ($ml)"
hm_ok "The chart renders and the CronJob carries the helper labels"

hm_info "Checking the release..."
hm_require_deployed reconcile
[ "$(hm_release_chart reconcile)" = "ledger-recon-0.2.0" ] || hm_fail "Release reconcile was not deployed from the ledger-recon chart"
live="$(kubectl get cronjob reconcile -n "$NS" -o json 2>/dev/null)" || hm_fail "CronJob reconcile does not exist"
[ "$(echo "$live" | jq -r '.metadata.labels."app.kubernetes.io/component" // empty')" = "reconciler" ] || hm_fail "Live CronJob lacks the helper labels (labels: $(echo "$live" | jq -c .metadata.labels))"
[ "$(echo "$live" | jq -r '.metadata.labels."app.kubernetes.io/instance" // empty')" = "reconcile" ] || hm_fail "Live CronJob has the wrong instance label"
[ "$(echo "$live" | jq -r '.spec.suspend // false')" = "false" ] || hm_fail "CronJob is suspended"
kubectl get configmap reconcile-config -n "$NS" >/dev/null 2>&1 || hm_fail "ConfigMap reconcile-config does not exist"

hm_pass "The nightly reconciliation is scheduled."
