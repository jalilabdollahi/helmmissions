#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install backup-scheduler "$SANDBOX/backup-scheduler" -n "$NS" >"$HM_TMP/install.txt" 2>&1 && { echo "setup: install succeeded"; exit 1; }
grep -q "no matches for kind" "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
[ -z "$(kubectl get crd backupschedules.helmissions.io -o name 2>/dev/null)" ] || { echo "setup: CRD already exists"; exit 1; }
