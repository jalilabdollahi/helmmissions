#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install echo "$SANDBOX/echo-api" -n "$NS" >/dev/null
for _ in $(seq 1 45); do
  reason="$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=echo -o jsonpath='{.items[0].status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || true)"
  case "$reason" in ErrImagePull|ImagePullBackOff) break ;; esac
  sleep 2
done
case "$reason" in ErrImagePull|ImagePullBackOff) ;; *) echo "setup: pods did not reach an image pull error (got: $reason)"; exit 1 ;; esac
