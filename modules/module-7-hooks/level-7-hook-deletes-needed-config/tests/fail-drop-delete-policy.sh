#!/bin/bash
# Partial fix: remove only the delete policy. The ConfigMap now survives, but it is still a hook resource,
# invisible in the release manifest and never cleaned up or reconciled by Helm.
set -euo pipefail
source "$HM_LIB"

python3 - "$SANDBOX/route-gateway/templates/routes-configmap.yaml" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
open(p, "w").write(s.replace('    "helm.sh/hook-delete-policy": hook-succeeded\n', ''))
PY
helm upgrade gateway ./route-gateway -n "$NS" --wait --timeout 90s
