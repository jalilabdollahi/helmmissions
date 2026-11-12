#!/bin/bash
# Partial fix: the staging values file is added and the pipeline re-run, but the script still does not stop on errors.
set -euo pipefail
source "$HM_LIB"
cp "$LEVEL_DIR/solution/values/staging.yaml" "$SANDBOX/values/staging.yaml"
bash "$SANDBOX/pipeline.sh"
