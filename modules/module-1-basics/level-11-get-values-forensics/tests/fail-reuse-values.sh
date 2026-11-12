#!/bin/bash
# `--reuse-values` re-applies the previous user values, override included.
set -euo pipefail
source "$HM_LIB"

helm upgrade weather-widget ./weather-widget -n "$NS" --reuse-values --wait --timeout 120s
