#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/render.sh" render.sh
chmod +x render.sh
./render.sh
kubectl apply -n "$NS" -f rendered/prod.yaml
