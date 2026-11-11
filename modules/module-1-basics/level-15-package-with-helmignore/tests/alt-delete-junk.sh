#!/bin/bash
# Valid: remove the local-only files from the working copy before packaging.
set -euo pipefail
source "$HM_LIB"

rm -rf "$SANDBOX/reports/secrets.local.env" "$SANDBOX/reports/tmp" "$SANDBOX/reports/"*.bak
helm package ./reports -d dist
helm install reports dist/reports-1.1.0.tgz -n "$NS" --wait --timeout 120s
