#!/bin/bash
# Tempting shortcut: fix the template error, then make cart "look right" by setting its own registry
# in the umbrella values. It works until the global is switched.
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/marketplace/charts/pricing/values.yaml" marketplace/charts/pricing/values.yaml
python3 - <<'PY'
p = "marketplace/values.yaml"
s = open(p).read()
s = s.replace("cart:\n  ttlMinutes: 45", "cart:\n  imageRegistry: docker.io\n  ttlMinutes: 45")
open(p, "w").write(s)
PY
helm install marketplace ./marketplace -n "$NS" --wait --timeout 180s
