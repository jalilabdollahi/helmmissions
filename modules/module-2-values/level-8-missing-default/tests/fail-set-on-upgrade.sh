#!/bin/bash
# Tempting: pass --set http.timeout=30 on the command line. The chart itself is unchanged.
set -euo pipefail
source "$HM_LIB"

helm upgrade fetcher ./fetcher -n "$NS" --set http.timeout=30 --wait --timeout 120s
