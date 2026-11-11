#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm repo add hm-stable "$HM_CHARTREPO_URL/m6-repo-not-added"
helm dependency update ./statuspage
helm install statuspage ./statuspage -n "$NS" --wait --timeout 120s
