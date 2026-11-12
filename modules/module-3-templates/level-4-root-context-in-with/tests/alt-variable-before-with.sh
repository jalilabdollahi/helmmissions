#!/bin/bash
# Alternative: capture the release name in a variable before entering the `with` block.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
python3 - "$SANDBOX/tileserver/templates/deployment.yaml" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("{{ $.Release.Name }}", "{{ $rel }}")
s = s.replace("        {{- with .Values.podLabels }}", "        {{- $rel := .Release.Name }}\n        {{- with .Values.podLabels }}")
open(p, "w").write(s)
PY
helm install tiles ./tileserver -n "$NS" --wait --timeout 120s
