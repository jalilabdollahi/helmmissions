#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Forward fix: keep everything from the current revision, flip only the broken setting.
helm upgrade product-search ./product-search -n "$NS" --reuse-values --set features.search=true --wait --timeout 120s
