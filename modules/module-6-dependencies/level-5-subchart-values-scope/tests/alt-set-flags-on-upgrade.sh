#!/bin/bash
# Valid alternative: leave values.yaml alone and scope the values to the subchart on the command line.
set -euo pipefail
source "$HM_LIB"

helm upgrade newsroom ./newsroom -n "$NS" \
  --set image-resizer.replicaCount=3 --set image-resizer.maxWidth=800 --set image-resizer.quality=70 \
  --wait --timeout 120s
