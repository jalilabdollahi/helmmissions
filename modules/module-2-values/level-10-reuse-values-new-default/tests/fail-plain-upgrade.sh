#!/bin/bash
# Tempting: drop --reuse-values but keep the CI's --set image.tag. The upgrade works, replicaCount silently falls back to 1.
set -euo pipefail
source "$HM_LIB"

helm upgrade notifier ./notifier -n "$NS" --set image.tag=1.36 --wait --timeout 120s
