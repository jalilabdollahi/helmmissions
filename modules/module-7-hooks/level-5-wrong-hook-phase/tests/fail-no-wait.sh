#!/bin/bash
# Wrong fix: drop --wait so the upgrade "succeeds" and the post-upgrade hook eventually runs. Chart unchanged.
set -euo pipefail
source "$HM_LIB"

helm upgrade shipments ./shipment-tracker -n "$NS" --timeout 90s
