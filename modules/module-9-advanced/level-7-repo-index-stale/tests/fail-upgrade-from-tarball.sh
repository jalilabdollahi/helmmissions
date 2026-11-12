#!/bin/bash
# Tempting shortcut: skip the repository and upgrade straight from the tarball.
set -euo pipefail
source "$HM_LIB"

helm upgrade tide-tracker repo/tide-tracker-1.3.0.tgz -n "$NS" --wait --timeout 120s
