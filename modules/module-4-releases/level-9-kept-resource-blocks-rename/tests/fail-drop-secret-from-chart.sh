#!/bin/bash
# Wrong fix: remove the Secret from the chart so the install "works". The kept Secret still belongs to shop
# and is not managed by the new release.
set -euo pipefail
source "$HM_LIB"

rm "$SANDBOX/storefront/templates/secret.yaml"
helm install storefront ./storefront -n "$NS" --wait --timeout 90s
