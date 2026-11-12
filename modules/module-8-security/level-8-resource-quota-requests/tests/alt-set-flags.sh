#!/bin/bash
# Valid alternative: resources via --set, no file edit.
set -euo pipefail
source "$HM_LIB"

helm upgrade search-indexer ./search-indexer -n "$NS" \
  --set resources.requests.cpu=40m --set resources.requests.memory=48Mi \
  --set resources.limits.cpu=80m --set resources.limits.memory=96Mi --wait --timeout 120s
