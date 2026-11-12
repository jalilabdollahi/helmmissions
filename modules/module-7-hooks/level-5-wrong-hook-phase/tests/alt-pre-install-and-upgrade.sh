#!/bin/bash
# Valid alternative: run the migration in both pre phases.
set -euo pipefail
source "$HM_LIB"

python3 - "$SANDBOX/shipment-tracker/templates/migrate-job.yaml" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
open(p, "w").write(s.replace('"helm.sh/hook": post-upgrade', '"helm.sh/hook": pre-upgrade,pre-install'))
PY
helm upgrade shipments ./shipment-tracker -n "$NS" --wait --timeout 90s
