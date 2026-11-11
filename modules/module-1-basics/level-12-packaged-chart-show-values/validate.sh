#!/bin/bash
set -uo pipefail
source "$HM_LIB"

# hm_http_check starts a one-shot pod; retry a few times so a slow kube-proxy sync is not a false negative.
http_retry() {
  local i
  for i in 1 2 3 4 5; do
    hm_http_check "$1" >"$HM_TMP/http.txt" 2>&1 && return 0
    sleep 3
  done
  return 1
}

hm_info "Checking the release..."
hm_require_deployed node-probe
chart="$(hm_release_chart node-probe)"
[ "$chart" = "node-probe-0.4.2" ] || hm_fail "Release node-probe runs chart '$chart', expected the vendor chart node-probe-0.4.2"

hm_info "Checking the Service..."
port="$(hm_jsonpath service/node-probe '{.spec.ports[0].port}')"
[ -n "$port" ] || hm_fail "Service node-probe does not exist"
[ "$port" = "9100" ] || hm_fail "Service node-probe listens on port $port, monitoring scrapes 9100"
mport="$(hm_manifest_json node-probe | jq -r '[.[] | select(.kind=="Service")][0].spec.ports[0].port')"
[ "$mport" = "9100" ] || hm_fail "Helm's record of the release says port $mport - the live Service was changed behind its back"
hm_wait_rollout deployment/node-probe "$NS" 90s
http_retry "http://node-probe.$NS.svc:9100/" || hm_fail "Nothing answers on http://node-probe.$NS.svc:9100/"
hm_ok "Service answers on 9100"

hm_info "Checking where the setting comes from..."
[ -f "$SANDBOX/probe-values.yaml" ] || hm_fail "probe-values.yaml is missing from the workspace - the setting must live in a reviewable values file"
fv="$(hm_yaml_get "$SANDBOX/probe-values.yaml" telemetry.servicePort)"
[ "$fv" = "9100" ] || hm_fail "probe-values.yaml does not set the Service port to 9100 under the key the chart reads (telemetry.servicePort gives $fv)"
uv="$(hm_user_values node-probe | jq -r '.telemetry.servicePort // empty')"
[ "$uv" = "9100" ] || hm_fail "The release's user-supplied values do not contain the port setting - was probe-values.yaml used for the install?"
[ -f "$SANDBOX/vendor/node-probe-0.4.2.tgz" ] || hm_fail "The vendor package was removed from the workspace"
hm_ok "probe-values.yaml drives the release"

hm_pass "node-probe exposes 9100 for monitoring."
