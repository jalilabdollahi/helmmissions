#!/bin/bash
# Valid alternative: flip the colour with a command line override instead of editing the values file.
set -euo pipefail
source "$HM_LIB"

helm upgrade ticket-booking ./ticket-booking -n "$NS" -f values-prod.yaml --set activeColor=blue
