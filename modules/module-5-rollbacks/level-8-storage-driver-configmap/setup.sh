#!/bin/bash
set -euo pipefail
source "$HM_LIB"

C="$LEVEL_DIR/assets/audit-gateway"
# The CI runner stores release state in ConfigMaps (HELM_DRIVER=configmap).
export HELM_DRIVER=configmap
helm install audit-gateway "$C" -n "$NS" --wait --timeout 90s >/dev/null
# 08:12 deploy: an unknown flag makes the container exit immediately
helm upgrade audit-gateway "$C" -n "$NS" --set 'extraArgs={--retention-days=30}' >/dev/null
st="$(helm status audit-gateway -n "$NS" -o json | jq -r '.info.status')"
[ "$st" = deployed ] || { echo "setup: configmap-driver release is '$st'"; exit 1; }
[ "$(helm history audit-gateway -n "$NS" -o json | jq length)" = "2" ] || { echo "setup: expected 2 revisions"; exit 1; }
unset HELM_DRIVER
[ -z "$(helm list -n "$NS" -q)" ] || { echo "setup: release should be invisible with the default driver"; exit 1; }
kubectl get configmap sh.helm.release.v1.audit-gateway.v2 -n "$NS" >/dev/null
for _ in $(seq 1 30); do
  kubectl get pods -n "$NS" -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' 2>/dev/null | grep -q CrashLoopBackOff && exit 0
  kubectl get pods -n "$NS" -o jsonpath='{.items[*].status.containerStatuses[*].lastState.terminated.reason}' 2>/dev/null | grep -q Error && exit 0
  sleep 2
done
echo "setup: pod is not crashing"; exit 1
