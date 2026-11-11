#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Helm happily installs a chart with no templates/ directory: an empty release.
helm install parcel-tracker "$SANDBOX/parcel-tracker" -n "$NS" >/dev/null
[ "$(hm_release_status parcel-tracker)" = deployed ] || { echo "setup: release not deployed"; exit 1; }
n="$(kubectl get deploy,svc,pods -n "$NS" -l app.kubernetes.io/name=parcel-tracker -o name | wc -l | tr -d ' ')"
[ "$n" = 0 ] || { echo "setup: resources unexpectedly exist"; exit 1; }
