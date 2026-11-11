#!/bin/bash
# Wrong fix: upgrade with only the one value, forgetting that previous --set values are not remembered.
set -euo pipefail
source "$HM_LIB"

helm upgrade product-search ./product-search -n "$NS" --set features.search=true --wait --timeout 90s
