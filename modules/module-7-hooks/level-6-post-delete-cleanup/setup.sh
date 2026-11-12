#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# A release that was installed and later uninstalled, leaving its runtime-created PVC behind.
helm install exports "$SANDBOX/export-batch" -n "$NS" --wait --timeout 90s >/dev/null
hm_assert_status exports deployed
kubectl get pvc exports-scratch -n "$NS" >/dev/null 2>&1 || { echo "setup: the scratch PVC was not created"; exit 1; }
helm uninstall exports -n "$NS" >/dev/null
[ -z "$(hm_release_status exports)" ] || { echo "setup: release still exists"; exit 1; }
kubectl get pvc exports-scratch -n "$NS" >/dev/null 2>&1 || { echo "setup: PVC unexpectedly removed by uninstall"; exit 1; }
