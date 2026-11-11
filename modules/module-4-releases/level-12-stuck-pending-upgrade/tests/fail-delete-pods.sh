#!/bin/bash
# Tempting wrong fix: bounce the pods / retry the upgrade. The pending record is what blocks Helm.
set -euo pipefail
source "$HM_LIB"

kubectl delete pods -n "$NS" -l app.kubernetes.io/name=warehouse-stock --now >/dev/null
helm upgrade warehouse-stock ./warehouse-stock -n "$NS" --timeout 30s || true
