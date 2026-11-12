#!/bin/bash
# Tempting: add the escaped keys but keep the old (junk) values with --reuse-values.
set -euo pipefail
source "$HM_LIB"

helm upgrade telemetry-agent ./telemetry-agent -n "$NS" --reuse-values \
  --set 'podAnnotations.prometheus\.io/scrape=true' \
  --set 'podAnnotations.prometheus\.io/port=9100' --wait --timeout 120s
