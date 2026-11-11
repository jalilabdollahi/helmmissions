#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The colleague's first deploy: it must fail at the Kubernetes API and leave a failed revision 1.
helm install invoice-api "$SANDBOX/invoice-api" -n "$NS" --timeout 60s >"$HM_TMP/install.txt" 2>&1 || true
st="$(hm_release_status invoice-api)"
[ "$st" = "failed" ] || { echo "setup: expected status failed, got '${st:-none}'"; cat "$HM_TMP/install.txt"; exit 1; }
grep -q "ClusterIp" "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
[ "$(hm_release_revision invoice-api)" = "1" ] || { echo "setup: expected exactly revision 1"; exit 1; }
