#!/bin/bash
# Any values file name works.
set -euo pipefail
source "$HM_LIB"

mkdir -p "$SANDBOX/env"
printf 'ingressHost: docs.staging.helmissions.local\n' >"$SANDBOX/env/staging.yml"
helm install docs-site ./docs-site -n "$NS" -f env/staging.yml --wait --timeout 120s
