#!/bin/bash
set -euo pipefail
source "$HM_LIB"

C="$SANDBOX/edge-throttle"
helm install edge-throttle "$C" -n "$NS" --wait --timeout 90s >/dev/null
# the bad change: the ConfigMap changes but, without a checksum, pods are NOT restarted by Helm...
helm upgrade edge-throttle "$C" -n "$NS" --reset-values --set rateLimit=1 --wait --timeout 90s >/dev/null
# ...until someone restarts them by hand, and they pick up the bad value
kubectl rollout restart deployment/edge-throttle -n "$NS" >/dev/null
kubectl rollout status deployment/edge-throttle -n "$NS" --timeout=90s >/dev/null
# wait until the pods of the previous ReplicaSet are really gone
for _ in $(seq 1 60); do
  [ "$(kubectl get pods -n "$NS" -l app.kubernetes.io/name=edge-throttle --no-headers 2>/dev/null | wc -l | tr -d ' ')" = "2" ] && break
  sleep 2
done
# the "fix": roll back. The ConfigMap is restored, the pod template is unchanged -> no restart.
helm rollback edge-throttle 1 -n "$NS" --wait --timeout 90s >/dev/null

hm_assert_status edge-throttle deployed
[ "$(hm_release_description edge-throttle)" = "Rollback to 1" ] || { echo "setup: expected a rollback revision"; exit 1; }
[ "$(hm_jsonpath configmap/edge-throttle-config '{.data.RATE_LIMIT}')" = "100" ] || { echo "setup: ConfigMap not restored"; exit 1; }
for p in $(kubectl get pods -n "$NS" -l app.kubernetes.io/name=edge-throttle -o name); do
  kubectl exec "$p" -n "$NS" -- cat /www/index.html | grep -q "rate_limit=1 " || { echo "setup: $p is not stuck on the bad value"; exit 1; }
done
