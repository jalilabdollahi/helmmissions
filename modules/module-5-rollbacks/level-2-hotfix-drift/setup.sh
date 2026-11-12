#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The release was created years ago by a client-side pipeline (Helm 3 era / --server-side=false).
flag=""; [ "$(hm_helm_major)" -ge 4 ] && flag="--server-side=false"
helm install order-sync "$SANDBOX/order-sync" -n "$NS" --set logLevel=info --set replicaCount=2 $flag --wait --timeout 90s >/dev/null
# On-call hotfix...
kubectl set env deployment/order-sync DB_POOL_SIZE=40 -n "$NS" >/dev/null
kubectl rollout status deployment/order-sync -n "$NS" --timeout=90s >/dev/null
# ...and then the regular pipeline run.
( cd "$SANDBOX" && helm upgrade --install order-sync ./order-sync -n "$NS" -f values-prod.yaml --wait --timeout 90s >/dev/null )

hm_assert_status order-sync deployed
[ "$(hm_release_revision order-sync)" = "2" ] || { echo "setup: expected revision 2"; exit 1; }
v="$(hm_jsonpath deployment/order-sync '{.spec.template.spec.containers[0].env[?(@.name=="DB_POOL_SIZE")].value}')"
[ "$v" = "5" ] || { echo "setup: hotfix was not reverted by the upgrade (DB_POOL_SIZE=$v)"; exit 1; }
