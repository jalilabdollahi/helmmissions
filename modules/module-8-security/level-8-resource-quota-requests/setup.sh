#!/bin/bash
set -euo pipefail
source "$HM_LIB"

kubectl apply -n "$NS" -f - >/dev/null <<'YAML'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: search-team-quota
spec:
  hard:
    pods: "4"
    requests.cpu: 200m
    requests.memory: 256Mi
    limits.cpu: 400m
    limits.memory: 512Mi
YAML
helm upgrade --install search-indexer "$SANDBOX/search-indexer" -n "$NS" >/dev/null
hm_assert_status search-indexer deployed
for _ in $(seq 1 30); do
  ev="$(kubectl get events -n "$NS" 2>/dev/null || true)"
  grep -q "failed quota: search-team-quota" <<<"$ev" && exit 0
  sleep 2
done
echo "setup: the quota rejection never appeared in events"; exit 1
