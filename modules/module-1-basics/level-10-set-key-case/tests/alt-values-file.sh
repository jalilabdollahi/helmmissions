#!/bin/bash
# Valid: put the setting in a values file.
set -euo pipefail
source "$HM_LIB"

printf 'replicaCount: 4\n' >"$SANDBOX/values-monthend.yaml"
helm upgrade billing ./billing -n "$NS" -f values-monthend.yaml --wait --timeout 120s
