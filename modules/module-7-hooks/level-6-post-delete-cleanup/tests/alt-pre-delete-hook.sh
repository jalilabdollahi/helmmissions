#!/bin/bash
# Valid alternative: clean the volume in a pre-delete hook instead of a post-delete one.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
python3 - "$SANDBOX/export-batch/templates/scratch-cleanup-job.yaml" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
open(p, "w").write(s.replace('"helm.sh/hook": post-delete', '"helm.sh/hook": pre-delete'))
PY
kubectl delete pvc exports-scratch -n "$NS"
