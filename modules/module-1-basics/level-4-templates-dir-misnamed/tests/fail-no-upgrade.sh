#!/bin/bash
# Renames the folder but never upgrades the release.
set -euo pipefail
source "$HM_LIB"

mv "$SANDBOX/parcel-tracker/template" "$SANDBOX/parcel-tracker/templates"
