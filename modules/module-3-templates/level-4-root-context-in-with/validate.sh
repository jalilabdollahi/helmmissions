#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/tileserver"
[ -f "$CHART/Chart.yaml" ] || hm_fail "tileserver/Chart.yaml is missing from the workspace"
labels() { jq -c '[.[] | select(.kind=="Deployment") | .spec.template.metadata.labels] | first // {}'; }

hm_info "Rendering the chart under two different release names..."
hm_render_json "$CHART" >"$HM_TMP/r.json" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
helm template other-name "$CHART" -n "$NS" 2>"$HM_TMP/err2.txt" | "$HM_PYTHON" -c 'import json,sys,yaml; print(json.dumps([d for d in yaml.safe_load_all(sys.stdin) if d]))' >"$HM_TMP/r2.json" || true
l1="$(labels <"$HM_TMP/r.json")"; l2="$(labels <"$HM_TMP/r2.json")"
[ "$(echo "$l1" | jq -r '."tileserver.example.com/release" // empty')" = "hm-render" ] \
  || hm_fail "The release label is missing or not the release name (labels: $l1)"
[ "$(echo "$l2" | jq -r '."tileserver.example.com/release" // empty')" = "other-name" ] \
  || hm_fail "The release label does not follow the release name (labels: $l2)"
[ "$(echo "$l1" | jq -r '.team // empty')" = "maps" ] || hm_fail "The podLabels from values.yaml are missing from the pod labels"
hm_ok "The chart renders and the labels follow the release name"

hm_info "Checking the release..."
hm_require_deployed tiles
[ "$(hm_release_chart tiles)" = "tileserver-2.0.0" ] || hm_fail "Release tiles was not deployed from the tileserver chart"
hm_wait_rollout deployment/tiles-tiles "$NS" 90s
pod="$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=tiles -o json | jq -c '.items[0].metadata.labels')"
[ "$(echo "$pod" | jq -r '."tileserver.example.com/release" // empty')" = "tiles" ] || hm_fail "The running pod lacks the release label (labels: $pod)"
[ "$(echo "$pod" | jq -r '.team // empty')" = "maps" ] || hm_fail "The running pod lacks the team label"
[ "$(hm_endpoints_count tiles-tiles)" -ge 1 ] || hm_fail "Service tiles-tiles has no ready endpoints"

hm_pass "tiles is deployed and its pods are labelled."
