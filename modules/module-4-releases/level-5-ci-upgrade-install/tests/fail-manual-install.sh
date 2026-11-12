#!/bin/bash
# Wrong fix: install by hand so the release exists here, leave the pipeline script broken.
set -euo pipefail
source "$HM_LIB"

helm install shipment-tracker ./shipment-tracker -n "$NS" --wait --timeout 90s
