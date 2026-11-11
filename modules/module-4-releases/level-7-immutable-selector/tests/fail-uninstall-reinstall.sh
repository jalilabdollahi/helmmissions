#!/bin/bash
# Wrong fix: uninstall and install 1.1 as is — works, but search is down meanwhile, history is lost and the
# selector changed.
set -euo pipefail
source "$HM_LIB"

helm uninstall catalog-search -n "$NS"
helm install catalog-search ./catalog-search -n "$NS" --wait --timeout 90s
