#!/bin/bash
# Tempting: a plain upgrade "from the chart". With no new values given, Helm carries the old user values over.
set -euo pipefail
source "$HM_LIB"

helm upgrade weather-widget ./weather-widget -n "$NS" --wait --timeout 120s
