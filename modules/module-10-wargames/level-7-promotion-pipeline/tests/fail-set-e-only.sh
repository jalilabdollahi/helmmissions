#!/bin/bash
# Partial fix: the script now stops on errors, but the missing staging values file is not provided.
set -euo pipefail
source "$HM_LIB"
cp "$LEVEL_DIR/solution/pipeline.sh" "$SANDBOX/pipeline.sh"
bash "$SANDBOX/pipeline.sh" || true
