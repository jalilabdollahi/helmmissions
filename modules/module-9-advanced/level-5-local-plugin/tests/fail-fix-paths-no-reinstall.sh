#!/bin/bash
# Partial fix: plugin.yaml paths are corrected, but the install hook never ran, so rules.env does not exist.
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/hm-audit/plugin.yaml" hm-audit/plugin.yaml
helm hm-audit checkout -n "$NS" || true
