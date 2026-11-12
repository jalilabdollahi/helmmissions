#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/hm-audit/plugin.yaml" hm-audit/plugin.yaml
helm plugin uninstall hm-audit
helm plugin install ./hm-audit
helm hm-audit checkout -n "$NS"
