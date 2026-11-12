#!/bin/bash
# Partial fix: the script picks values-prod.yaml now, but --reuse-values still drags the dev-only keys along.
set -euo pipefail
source "$HM_LIB"
cp "$LEVEL_DIR/solution/values-prod.yaml" "$SANDBOX/values-prod.yaml"
perl -0pi -e 's/RELEASE=invoice\n    VALUES=values-dev.yaml/RELEASE=invoice\n    VALUES=values-prod.yaml/' "$SANDBOX/deploy.sh"
bash "$SANDBOX/deploy.sh" prod
