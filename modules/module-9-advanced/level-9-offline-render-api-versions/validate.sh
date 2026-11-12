#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/checkout"
SM="servicemonitors.monitoring.helmissions.io"
to_json() { "$HM_PYTHON" -c 'import json,sys,yaml; print(json.dumps([d for d in yaml.safe_load_all(open(sys.argv[1])) if d]))' "$1"; }

hm_info "Checking the chart still guards the ServiceMonitor..."
[ -f "$CHART/Chart.yaml" ] && [ -f "$SANDBOX/render.sh" ] || hm_fail "The chart or render.sh is missing from the workspace"
plain="$(hm_render_json "$CHART" -f "$SANDBOX/env/prod.yaml")" || true
[ -n "$plain" ] && [ "$plain" != "[]" ] || hm_fail "helm template of the chart fails" "$HM_TMP/render-err.txt"
echo "$plain" | jq -e 'any(.[]; .kind=="ServiceMonitor")' >/dev/null \
  && hm_fail "The chart renders a ServiceMonitor even when the monitoring API is not available — the capability guard was removed"
withapi="$(hm_render_json "$CHART" -f "$SANDBOX/env/prod.yaml" --api-versions monitoring.helmissions.io/v1)" || true
echo "$withapi" | jq -e 'any(.[]; .kind=="ServiceMonitor")' >/dev/null || hm_fail "The chart no longer renders a ServiceMonitor when the monitoring API is available"
hm_ok "Capability guard intact"

hm_info "Running render.sh the way CI does..."
rendered="$SANDBOX/rendered/prod.yaml"
[ -f "$rendered" ] || hm_fail "rendered/prod.yaml does not exist"
cp "$rendered" "$HM_TMP/committed.yaml"
(cd "$SANDBOX" && bash ./render.sh >"$HM_TMP/render-run.txt" 2>&1) || hm_fail "render.sh fails" "$HM_TMP/render-run.txt"
cp "$rendered" "$HM_TMP/fresh.yaml"
cp "$HM_TMP/committed.yaml" "$rendered"
to_json "$HM_TMP/fresh.yaml" | jq -e 'any(.[]; .kind=="ServiceMonitor" and .metadata.name=="checkout")' >/dev/null \
  || hm_fail "render.sh output contains no ServiceMonitor checkout"
to_json "$HM_TMP/fresh.yaml" | jq -e 'any(.[]; .kind=="ServiceMonitor" and .spec.endpoints[0].interval=="15s")' >/dev/null \
  || hm_fail "The rendered ServiceMonitor does not use the 15s interval from env/prod.yaml"
diff -q "$HM_TMP/fresh.yaml" "$HM_TMP/committed.yaml" >/dev/null 2>&1 \
  || hm_fail "rendered/prod.yaml is not what render.sh produces — regenerate it with the script instead of editing it by hand"
hm_ok "render.sh produces the ServiceMonitor and rendered/prod.yaml is its output"

hm_info "Checking the cluster..."
live="$(kubectl get "$SM" checkout -n "$NS" -o json 2>/dev/null)" || hm_fail "ServiceMonitor checkout does not exist in namespace $NS"
[ "$(echo "$live" | jq -r '.spec.endpoints[0].interval')" = 15s ] || hm_fail "The live ServiceMonitor does not have the 15s interval"
hm_wait_rollout deployment/checkout "$NS" 90s
[ "$(hm_endpoints_count checkout)" -ge 2 ] || hm_fail "Service checkout has fewer than 2 ready endpoints"
hm_pass "The GitOps render keeps the ServiceMonitor and it is applied."
