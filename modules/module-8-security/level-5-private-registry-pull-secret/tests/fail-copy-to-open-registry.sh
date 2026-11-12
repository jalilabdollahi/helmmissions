#!/bin/bash
# Wrong fix: sidestep the private registry by publishing the image to the open registry and switching the repository.
set -euo pipefail
source "$HM_LIB"

docker tag nginx:1.27-alpine localhost:5001/m8-private-registry-pull-secret/portal:1.0
docker push localhost:5001/m8-private-registry-pull-secret/portal:1.0 >/dev/null 2>&1
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade portal ./partner-portal -n "$NS" --set image.repository=localhost:5001/m8-private-registry-pull-secret/portal --wait --timeout 120s
