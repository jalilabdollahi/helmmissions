#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The cluster has the CRD (installed by the monitoring stack).
for _ in $(seq 1 30); do kubectl apply -f "$LEVEL_DIR/assets/crd.yaml" >/dev/null 2>&1 && break; sleep 2; done
kubectl wait --for=condition=Established crd/servicemonitors.monitoring.helmissions.io --timeout=60s >/dev/null

# CI ran render.sh and the pipeline applied the output.
(cd "$SANDBOX" && bash ./render.sh >/dev/null)
kubectl apply -n "$NS" -f "$SANDBOX/rendered/prod.yaml" >/dev/null
kubectl rollout status deployment/checkout -n "$NS" --timeout=90s >/dev/null
if grep -q 'kind: ServiceMonitor' "$SANDBOX/rendered/prod.yaml"; then echo "setup: the render already has a ServiceMonitor"; exit 1; fi
if kubectl get servicemonitors.monitoring.helmissions.io checkout -n "$NS" >/dev/null 2>&1; then echo "setup: ServiceMonitor already exists"; exit 1; fi
# ... while installing directly does render it (proves the premise).
helm template probe "$SANDBOX/checkout" -n "$NS" -f "$SANDBOX/env/prod.yaml" --dry-run=server 2>/dev/null | grep -q 'kind: ServiceMonitor' \
  || { echo "setup: a cluster-aware render should include the ServiceMonitor"; exit 1; }
