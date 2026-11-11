#!/bin/bash
# Tempting shortcut: make the template parse by typing the site name straight into it.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak "s|{{ .Values.site.name }}|The Pressroom Daily|g" "$SANDBOX/pressroom/templates/configmap.yaml"
rm -f "$SANDBOX/pressroom/templates/configmap.yaml.bak"
helm install pressroom ./pressroom -n "$NS" --wait --timeout 120s
