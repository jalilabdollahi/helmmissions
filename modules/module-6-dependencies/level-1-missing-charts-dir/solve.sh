#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm dependency update ./storefront
helm install storefront ./storefront -n "$NS" --wait --timeout 120s
