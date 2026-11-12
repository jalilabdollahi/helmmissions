#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
rm -f "$SANDBOX/backup-scheduler/templates/crd.yaml"
helm install backup-scheduler ./backup-scheduler -n "$NS" --wait --timeout 120s
