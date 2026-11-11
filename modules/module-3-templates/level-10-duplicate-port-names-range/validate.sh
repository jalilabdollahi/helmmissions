#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/mesh-edge"
[ -f "$CHART/Chart.yaml" ] || hm_fail "mesh-edge/Chart.yaml is missing from the workspace"
svc_ports() { jq -c '[.[] | select(.kind=="Service") | .spec.ports[] | {name, port}] | sort_by(.port)'; }
want="$(hm_yaml_get "$CHART/values.yaml" ports | jq -c '[.[] | {port}] | sort_by(.port)')"
[ "$(echo "$want" | jq length)" -ge 3 ] || hm_fail "values.yaml lists only $(echo "$want" | jq length) port(s) - the http, admin and metrics ports must all stay exposed"
check() { # json-array-of-{name,port}
  [ "$(echo "$1" | jq 'length')" = "$(echo "$want" | jq 'length')" ] || return 1
  [ "$(echo "$1" | jq '[.[].name] | unique | length')" = "$(echo "$1" | jq 'length')" ] || return 2
  [ "$(echo "$1" | jq -c '[.[] | {port}]')" = "$want" ] || return 3
}

hm_info "Rendering the chart from the workspace..."
hm_render_json "$CHART" >"$HM_TMP/r.json" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
p="$(svc_ports <"$HM_TMP/r.json")"
check "$p"; rc=$?
[ $rc -ne 1 ] || hm_fail "The Service renders $(echo "$p" | jq length) port(s), the values list defines $(echo "$want" | jq length): $p"
[ $rc -ne 2 ] || hm_fail "The rendered Service still has duplicate port names: $(echo "$p" | jq -c '[.[].name]')"
[ $rc -ne 3 ] || hm_fail "The rendered Service port numbers do not match the values list: $p"
hm_ok "Rendered Service ports are unique and complete"

hm_info "Checking the release..."
hm_require_deployed edge
[ "$(hm_release_chart edge)" = "mesh-edge-0.7.0" ] || hm_fail "Release edge was not deployed from the mesh-edge chart"
live="$(kubectl get svc edge -n "$NS" -o json 2>/dev/null | jq -c '[.spec.ports[] | {name, port}] | sort_by(.port)')" || true
check "${live:-[]}" || hm_fail "Live Service edge ports are wrong: $live"
hm_wait_rollout deployment/edge "$NS" 90s
[ "$(hm_endpoints_count edge)" -ge 1 ] || hm_fail "Service edge has no ready endpoints"
ok=""; for _ in 1 2 3 4; do hm_http_check "http://edge.$NS.svc.cluster.local/health" >/dev/null && ok=1 && break; sleep 3; done
[ -n "$ok" ] || hm_fail "Service edge does not answer on its http port"

hm_pass "edge exposes all its ports."
