#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/orders-api"
[ -f "$CHART/Chart.yaml" ] || hm_fail "orders-api/Chart.yaml is missing from the workspace"
dbhost() { jq -r '[.[] | select(.kind=="Deployment" and (.metadata.name | endswith("-api"))) | .spec.template.spec.containers[0].env[]? | select(.name=="DB_HOST") | .value] | first // empty'; }

hm_info "Rendering the chart under two release names..."
hm_render_json "$CHART" >"$HM_TMP/a.json" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
h1="$(dbhost <"$HM_TMP/a.json")"
[ "$h1" = "hm-render-db" ] || hm_fail "DB_HOST renders as '$h1' for release hm-render, expected 'hm-render-db'"
helm template canary-9 "$CHART" -n "$NS" 2>"$HM_TMP/e2.txt" | "$HM_PYTHON" -c 'import json,sys,yaml; print(json.dumps([d for d in yaml.safe_load_all(sys.stdin) if d]))' >"$HM_TMP/b.json" || hm_fail "helm template fails for another release name"
h2="$(dbhost <"$HM_TMP/b.json")"
[ "$h2" = "canary-9-db" ] || hm_fail "DB_HOST renders as '$h2' for release canary-9, expected 'canary-9-db' - it must follow the release name"
hm_ok "DB_HOST follows the release name"

hm_info "Checking the release..."
hm_require_deployed orders
rev="$(hm_release_revision orders)"
[ "${rev:-0}" -ge 2 ] || hm_fail "Release orders is still at revision ${rev:-?} - the fixed chart was never deployed"
[ "$(hm_manifest_json orders | dbhost)" = "orders-db" ] || hm_fail "The release manifest has DB_HOST='$(hm_manifest_json orders | dbhost)'"
hm_wait_rollout deployment/orders-api "$NS" 90s
live="$(kubectl get pods -n "$NS" -l app=orders-api -o json | jq -r '[.items[] | select(.metadata.deletionTimestamp==null)] | first | .spec.containers[0].env[] | select(.name=="DB_HOST") | .value')"
[ "$live" = "orders-db" ] || hm_fail "The running pod has DB_HOST='$live'"
ready="$(hm_jsonpath deployment/orders-api '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 1 ] || hm_fail "The orders-api pod is not Ready"

hm_pass "orders-api reaches its database."
