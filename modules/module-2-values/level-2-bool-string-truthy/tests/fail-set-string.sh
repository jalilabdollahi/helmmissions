#!/bin/bash
# Wrong fix: --set-string keeps the value a string, so the template still sees a truthy value.
set -euo pipefail
source "$HM_LIB"

helm upgrade storefront ./storefront -n "$NS" --set-string ingress.enabled=false --wait --timeout 120s
