#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
rm -rf "$SANDBOX/parcel-tracker/template"
helm upgrade parcel-tracker ./parcel-tracker -n "$NS" --wait --timeout 120s
