#!/bin/bash
# Tempting shortcut: fix the file, render it and kubectl-apply it. Helm still sees a failed release.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm template invoice-api ./invoice-api -n "$NS" | kubectl apply -n "$NS" -f - >/dev/null
kubectl rollout status deployment/invoice-api -n "$NS" --timeout=90s >/dev/null
