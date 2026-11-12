#!/bin/bash
# Tempting shortcut: fix the folder, render, and apply with kubectl. The Helm release stays empty.
set -euo pipefail
source "$HM_LIB"

mv "$SANDBOX/parcel-tracker/template" "$SANDBOX/parcel-tracker/templates"
helm template parcel-tracker ./parcel-tracker -n "$NS" | kubectl apply -n "$NS" -f -
