#!/bin/bash
# Alternative: clear the stuck operation by deleting the pending revision's record instead of rolling back.
set -euo pipefail
source "$HM_LIB"
cd "$SANDBOX"
helm dependency update ./tideline --plain-http >/dev/null
rev="$(hm_release_revision tideline)"
kubectl delete secret "sh.helm.release.v1.tideline.v$rev" -n "$NS"
cp "$LEVEL_DIR/solution/values/prod.yaml" values/prod.yaml
cp "$LEVEL_DIR/solution/values/staging.yaml" values/staging.yaml
bash deploy.sh staging
bash deploy.sh prod
