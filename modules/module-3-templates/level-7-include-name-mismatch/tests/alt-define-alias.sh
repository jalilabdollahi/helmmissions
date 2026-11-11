#!/bin/bash
# Alternative: keep the old name working by adding an alias definition in _helpers.tpl.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/include "storefront.labels" . | nindent 4 }}$/&/' "$SANDBOX/storefront/templates/service.yaml"
python3 - "$SANDBOX/storefront/templates/service.yaml" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace('include "storefront.labels"', 'include "shop.labels"')
open(p, "w").write(s)
PY
rm -f "$SANDBOX/storefront/templates/service.yaml.bak"
cat >> "$SANDBOX/storefront/templates/_helpers.tpl" <<'EOF'

{{- define "shop.labels" -}}
{{ include "storefront.labels" . }}
{{- end -}}
EOF
helm install shop ./storefront -n "$NS" --wait --timeout 120s
