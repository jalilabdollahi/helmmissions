#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install image-resizer "$SANDBOX/image-resizer" -n "$NS" >"$HM_TMP/out.txt" 2>&1 || true
[ "$(hm_release_status image-resizer)" = failed ] || { cat "$HM_TMP/out.txt"; echo "setup: expected a failed release"; exit 1; }
