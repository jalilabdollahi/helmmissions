#!/bin/bash
# Valid alternative: keep the chart as shipped and pin the storage value on the command line.
set -euo pipefail
source "$HM_LIB"

helm upgrade tsdb ./timeseries-db -n "$NS" --set storage=1Gi --wait --timeout 120s
