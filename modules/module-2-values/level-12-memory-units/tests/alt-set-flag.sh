#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm upgrade image-resizer ./image-resizer -n "$NS" --set resources.limits.memory=256Mi --wait --timeout 120s
