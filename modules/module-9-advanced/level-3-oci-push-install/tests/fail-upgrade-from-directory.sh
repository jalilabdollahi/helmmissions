#!/bin/bash
# Tempting shortcut: skip the registry and upgrade from the chart directory.
set -euo pipefail
source "$HM_LIB"

helm upgrade payments-gateway ./payments-gateway -n "$NS" --wait --timeout 120s
