#!/bin/bash
# Works once, but the staging setting is not kept in any file the team can review or reuse.
set -euo pipefail
source "$HM_LIB"

helm install docs-site ./docs-site -n "$NS" --set ingressHost=docs.staging.helmissions.local --wait --timeout 120s
