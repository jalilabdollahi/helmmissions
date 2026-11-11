#!/bin/bash
# Valid: rename and reinstall from scratch.
set -euo pipefail
source "$HM_LIB"

mv "$SANDBOX/parcel-tracker/template" "$SANDBOX/parcel-tracker/templates"
helm uninstall parcel-tracker -n "$NS"
helm install parcel-tracker ./parcel-tracker -n "$NS" --wait --timeout 120s
