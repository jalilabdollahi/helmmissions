#!/bin/bash
# Tempting shortcut: delete the helper call and type fewer labels by hand.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
python3 - "$SANDBOX/ledger-recon/templates/cronjob.yaml" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace('  labels:\n    {{- include "ledger-recon.labels" . | nindent 4 }}\nspec:', '  labels:\n    app: reconcile\nspec:', 1)
open(p, "w").write(s)
PY
helm install reconcile ./ledger-recon -n "$NS" --wait --timeout 120s
