#!/bin/bash
set -uo pipefail
source "$HM_LIB"

AN=helmissions-api; WN=helmissions-web
hm_info "Checking the releases..."
hm_require_deployed orders-api "$AN"
hm_require_deployed orders-web "$WN"
hm_wait_rollout deployment/orders-api "$AN" 60s
hm_wait_rollout deployment/orders-web "$WN" 60s
[ "$(hm_endpoints_count orders-api "$AN")" -ge 1 ] || hm_fail "Service orders-api in $AN has no ready endpoints"

hm_info "Checking the workspace, the release records and the live objects agree..."
dp_render="$(hm_render_json "$SANDBOX/orders-web" -n "$WN" | jq -r '[.[]|select(.kind=="Deployment")][0].spec.template.spec.dnsPolicy')"
dp_live="$(kubectl get deployment orders-web -n "$WN" -o jsonpath='{.spec.template.spec.dnsPolicy}')"
dp_rel="$(hm_manifest_json orders-web "$WN" | jq -r '[.[]|select(.kind=="Deployment")][0].spec.template.spec.dnsPolicy')"
[ "$dp_live" = "ClusterFirst" ] && [ "$dp_rel" = "ClusterFirst" ] && [ "$dp_render" = "ClusterFirst" ] || hm_fail "The front end pods do not use the cluster resolver consistently (workspace: $dp_render, release: $dp_rel, live: $dp_live)"
h_render="$(hm_render_json "$SANDBOX/orders-web" | jq -r '[.[]|select(.kind=="Deployment")][0].spec.template.spec.containers[0].env[]|select(.name=="ORDERS_API_HOST").value')"
h_live="$(kubectl get deployment orders-web -n "$WN" -o json | jq -r '.spec.template.spec.containers[0].env[]|select(.name=="ORDERS_API_HOST").value')"
[ "$h_render" = "$h_live" ] || hm_fail "The workspace would deploy a different back-end address ('$h_render') than the one running ('$h_live')"
tp_render="$(hm_render_json "$SANDBOX/orders-api" | jq -r '[.[]|select(.kind=="Service")][0].spec.ports[0].targetPort')"
tp_live="$(kubectl get service orders-api -n "$AN" -o jsonpath='{.spec.ports[0].targetPort}')"
[ "$tp_render" = "$tp_live" ] || hm_fail "The workspace would deploy a different Service target port ('$tp_render') than the live one ('$tp_live')"
hm_ok "Workspace and cluster agree"

hm_info "Checking the dashboard..."
for _ in 1 2 3 4; do
  hm_http_check http://orders-web/cgi-bin/dashboard "$WN" >"$HM_TMP/d.txt" 2>/dev/null
  grep -q "orders: 42 open" "$HM_TMP/d.txt" && break
  sleep 3
done
grep -q "orders: 42 open" "$HM_TMP/d.txt" || hm_fail "The dashboard does not show the open orders" "$HM_TMP/d.txt"
grep -q "served from $AN" "$HM_TMP/d.txt" || hm_fail "The dashboard is not served by the back end in $AN" "$HM_TMP/d.txt"
hm_pass "The front end reaches the back end across namespaces."
