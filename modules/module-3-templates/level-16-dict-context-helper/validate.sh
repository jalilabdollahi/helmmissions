#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/mailer"
[ -f "$CHART/Chart.yaml" ] || hm_fail "mailer/Chart.yaml is missing from the workspace"
depnames() { jq -c '[.[] | select(.kind=="Deployment") | .metadata.name] | sort'; }
comps() { jq -c '[.[] | select(.kind=="Deployment") | .spec.template.metadata.labels."app.kubernetes.io/component"] | sort'; }

hm_info "Rendering the chart under a custom release name..."
helm lint "$CHART" >"$HM_TMP/lint.txt" 2>&1 || hm_fail "helm lint reports errors" "$HM_TMP/lint.txt"
helm template zeta "$CHART" -n "$NS" 2>"$HM_TMP/render-err.txt" | "$HM_PYTHON" -c 'import json,sys,yaml; print(json.dumps([d for d in yaml.safe_load_all(sys.stdin) if d]))' >"$HM_TMP/r.json" || true
[ -s "$HM_TMP/r.json" ] && [ "$(jq length "$HM_TMP/r.json" 2>/dev/null || echo 0)" -gt 0 ] || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
[ "$(depnames <"$HM_TMP/r.json")" = '["zeta-api","zeta-worker"]' ] || hm_fail "Deployments are named $(depnames <"$HM_TMP/r.json"), expected [\"zeta-api\",\"zeta-worker\"] for release zeta"
[ "$(comps <"$HM_TMP/r.json")" = '["api","worker"]' ] || hm_fail "Pod component labels are $(comps <"$HM_TMP/r.json"), expected api and worker"
sel="$(jq -c '[.[] | select(.kind=="Service") | .spec.selector."app.kubernetes.io/component"] | first' "$HM_TMP/r.json")"
[ "$sel" = '"api"' ] || hm_fail "The Service selector has component $sel, expected \"api\""
hm_ok "Both components render with distinct names and labels"

hm_info "Checking the release..."
hm_require_deployed mailer
[ "$(hm_release_chart mailer)" = "mailer-1.8.0" ] || hm_fail "Release mailer was not deployed from the mailer chart"
for d in mailer-api mailer-worker; do
  kubectl get deployment "$d" -n "$NS" >/dev/null 2>&1 || hm_fail "Deployment $d does not exist"
  hm_wait_rollout "deployment/$d" "$NS" 90s
done
[ "$(hm_endpoints_count mailer-api)" -ge 1 ] || hm_fail "Service mailer-api has no ready endpoints"

hm_pass "mailer's api and worker are both running."
