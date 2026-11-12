#!/bin/bash
# Alternative: write the default as a pipeline.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/{{ default .Chart.AppVersion .Values.image.tag }}/{{ .Values.image.tag | default .Chart.AppVersion }}/' "$SANDBOX/echo-api/templates/_helpers.tpl"
rm -f "$SANDBOX/echo-api/templates/_helpers.tpl.bak"
helm upgrade echo ./echo-api -n "$NS" --wait --timeout 120s
