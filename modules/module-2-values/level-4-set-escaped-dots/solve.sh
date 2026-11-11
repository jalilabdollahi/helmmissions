#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm upgrade telemetry-agent ./telemetry-agent -n "$NS" \
  --set 'podAnnotations.prometheus\.io/scrape=true' \
  --set 'podAnnotations.prometheus\.io/port=9100' --wait --timeout 120s
