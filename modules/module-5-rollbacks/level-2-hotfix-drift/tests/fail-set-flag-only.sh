#!/bin/bash
# Wrong fix: a one-off --set on the command line. Release is healthy but the files still say 5.
set -euo pipefail
source "$HM_LIB"

helm upgrade order-sync ./order-sync -n "$NS" -f values-prod.yaml --set db.poolSize=40 --wait --timeout 90s
