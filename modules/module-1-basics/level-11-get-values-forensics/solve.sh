#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm upgrade weather-widget ./weather-widget -n "$NS" --reset-values --wait --timeout 120s
