#!/bin/bash
# Valid: supply new (empty-of-override) values from a file, which replaces the stored ones.
set -euo pipefail
source "$HM_LIB"

printf 'replicaCount: 1\n' >"$SANDBOX/values-portal.yaml"
helm upgrade weather-widget ./weather-widget -n "$NS" -f values-portal.yaml --wait --timeout 120s
