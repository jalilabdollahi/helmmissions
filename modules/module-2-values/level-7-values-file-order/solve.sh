#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/deploy.sh" ./deploy.sh
bash ./deploy.sh
