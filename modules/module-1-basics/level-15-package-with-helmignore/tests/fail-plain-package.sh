#!/bin/bash
# Packages and installs, but the archive still contains the local-only files.
set -euo pipefail
source "$HM_LIB"

helm package ./reports -d dist
helm install reports dist/reports-1.1.0.tgz -n "$NS" --wait --timeout 120s
