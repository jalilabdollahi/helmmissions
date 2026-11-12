#!/bin/bash
# Tempting shortcut: drop the default entirely - works for the pinned tag but loses the appVersion fallback.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/{{ default .Chart.AppVersion .Values.image.tag }}/{{ .Values.image.tag }}/' "$SANDBOX/echo-api/templates/_helpers.tpl"
rm -f "$SANDBOX/echo-api/templates/_helpers.tpl.bak"
helm upgrade echo ./echo-api -n "$NS" --wait --timeout 120s
