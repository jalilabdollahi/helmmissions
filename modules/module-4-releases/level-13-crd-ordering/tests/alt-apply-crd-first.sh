#!/bin/bash
# Valid alternative: the CRD is applied out of band (kubectl), the chart only ships the resource and controller.
set -euo pipefail
source "$HM_LIB"

kubectl apply -f "$LEVEL_DIR/solution/backup-scheduler/crds/backupschedule-crd.yaml"
kubectl wait --for=condition=Established crd/backupschedules.helmissions.io --timeout=60s
rm "$SANDBOX/backup-scheduler/templates/crd.yaml"
helm install backup-scheduler "$SANDBOX/backup-scheduler" -n "$NS" --wait --timeout 90s
