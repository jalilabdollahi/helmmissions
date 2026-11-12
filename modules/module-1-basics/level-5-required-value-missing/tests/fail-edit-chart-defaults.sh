#!/bin/bash
# Hardcodes the staging host in the shared chart's defaults.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/^ingressHost: ""/ingressHost: docs.staging.helmissions.local/' "$SANDBOX/docs-site/values.yaml" && rm -f "$SANDBOX/docs-site/values.yaml.bak"
helm install docs-site ./docs-site -n "$NS" --wait --timeout 120s
