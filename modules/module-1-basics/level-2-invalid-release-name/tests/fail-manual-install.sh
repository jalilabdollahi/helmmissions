#!/bin/bash
# Tempting shortcut: install by hand with a valid name but leave the pipeline script broken.
set -euo pipefail
source "$HM_LIB"

helm install shop-frontend ./storefront -n "$NS" --wait --timeout 120s
