#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Helm installs crds/ once and never updates them - apply the new CRD yourself, then upgrade.
kubectl apply -f snapshot-scheduler/crds/
helm upgrade snapshots ./snapshot-scheduler -n "$NS" --wait --timeout 90s
