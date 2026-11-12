#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm upgrade notifier ./notifier -n "$NS" --reset-then-reuse-values --set image.tag=1.36 --wait --timeout 120s
