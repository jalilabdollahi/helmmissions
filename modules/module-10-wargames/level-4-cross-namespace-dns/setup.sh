#!/bin/bash
set -euo pipefail
source "$HM_LIB"
kubectl create namespace helmissions-api >/dev/null
kubectl create namespace helmissions-web >/dev/null
cd "$SANDBOX"
helm install orders-api ./orders-api -n helmissions-api --wait --timeout 60s >/dev/null
helm install orders-web ./orders-web -n helmissions-web --wait --timeout 60s >/dev/null
hm_assert_status orders-api deployed helmissions-api
hm_assert_status orders-web deployed helmissions-web
hm_http_check http://orders-web/cgi-bin/dashboard helmissions-web >"$HM_TMP/d.txt" || { echo "setup: dashboard page not reachable"; exit 1; }
grep -q "orders: 42" "$HM_TMP/d.txt" && { echo "setup: dashboard already works"; exit 1; }
exit 0
