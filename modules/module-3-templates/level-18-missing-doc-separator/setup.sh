#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install status "$SANDBOX/status-page" -n "$NS" >/dev/null
[ "$(hm_release_status status)" = "deployed" ] || { echo "setup: release is not deployed"; exit 1; }
kubectl get svc status -n "$NS" >/dev/null 2>&1 || { echo "setup: the Service should exist"; exit 1; }
if kubectl get deploy status -n "$NS" >/dev/null 2>&1; then echo "setup: the Deployment unexpectedly exists"; exit 1; fi
