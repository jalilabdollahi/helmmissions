#!/bin/bash
# Valid alternative: plain upgrade, re-supplying the override explicitly.
set -euo pipefail
source "$HM_LIB"

helm upgrade notifier ./notifier -n "$NS" --set replicaCount=2 --set image.tag=1.36 --wait --timeout 120s
