#!/bin/bash
# Tempting partial fix: change the spelling in the wrong direction (still never true), keep installing.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's#networking.k8s.io/v1/Ingress#networking.k8s.io/v1beta1/Ingress#' "$SANDBOX/docs-portal/templates/_helpers.tpl"
rm -f "$SANDBOX/docs-portal/templates/_helpers.tpl.bak"
helm install portal ./docs-portal -n "$NS" --timeout 30s || true
