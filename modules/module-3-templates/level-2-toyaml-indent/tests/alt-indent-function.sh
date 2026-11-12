#!/bin/bash
# Alternative: use `indent` with an explicit newline instead of nindent.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
python3 - "$SANDBOX/geoip/templates/deployment.yaml" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("          resources:\n            {{- toYaml .Values.resources | nindent 12 }}",
              "          resources:\n{{ toYaml .Values.resources | indent 12 }}")
open(p, "w").write(s)
PY
helm upgrade --install geoip ./geoip -n "$NS" --wait --timeout 120s
