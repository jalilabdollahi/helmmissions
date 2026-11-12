#!/bin/bash
# Wrong fix: upgrade the unchanged chart - the ConfigMap is already right, the pod template is identical, nothing restarts.
set -euo pipefail
source "$HM_LIB"

helm upgrade edge-throttle ./edge-throttle -n "$NS" --wait --timeout 90s
