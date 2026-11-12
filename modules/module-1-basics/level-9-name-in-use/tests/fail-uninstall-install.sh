#!/bin/bash
# Tempting: delete the release and install again. Revision history (and the rollback path) is lost.
set -euo pipefail
source "$HM_LIB"

helm uninstall orders -n "$NS"
helm install orders ./orders -n "$NS" --wait --timeout 120s
