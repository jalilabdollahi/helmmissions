#!/bin/bash
# Alternative: keep `indent` but put the call on its own line after a literal newline.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
python3 - "$SANDBOX/ledger-recon/templates/cronjob.yaml" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace('  labels:\n    {{- include "ledger-recon.labels" . | nindent 4 }}\nspec:', '  labels:\n{{ include "ledger-recon.labels" . | indent 4 }}\nspec:', 1)
open(p, "w").write(s)
PY
helm install reconcile ./ledger-recon -n "$NS" --wait --timeout 120s
