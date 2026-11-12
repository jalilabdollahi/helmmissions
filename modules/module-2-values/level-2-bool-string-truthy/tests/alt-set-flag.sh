#!/bin/bash
# Valid alternative: override with a typed --set (becomes a boolean).
set -euo pipefail
source "$HM_LIB"

helm upgrade storefront ./storefront -n "$NS" --set ingress.enabled=false --wait --timeout 120s
