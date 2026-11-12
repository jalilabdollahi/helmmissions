#!/bin/bash
# Valid alternative: Secret hook with an explicit before-hook-creation policy and weight lower than the Job's.
set -euo pipefail
source "$HM_LIB"

python3 - "$SANDBOX/payroll-api/templates/secret.yaml" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace('  labels:\n    app.kubernetes.io/name: payroll-api\n', '  labels:\n    app.kubernetes.io/name: payroll-api\n  annotations:\n    "helm.sh/hook": pre-install\n    "helm.sh/hook-weight": "-20"\n    "helm.sh/hook-delete-policy": before-hook-creation\n')
open(p, "w").write(s)
PY
helm uninstall payroll -n "$NS" --wait >/dev/null
helm install payroll ./payroll-api -n "$NS" --wait --timeout 90s
