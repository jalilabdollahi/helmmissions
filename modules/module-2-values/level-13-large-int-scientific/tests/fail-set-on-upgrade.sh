#!/bin/bash
# Tempting: --set (parsed as an integer) fixes this one release but not the chart.
set -euo pipefail
source "$HM_LIB"

helm upgrade upload-proxy ./upload-proxy -n "$NS" --set maxUploadBytes=1048576 --wait --timeout 120s
