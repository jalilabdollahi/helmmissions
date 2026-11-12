#!/bin/bash
# Alternative: leave the subchart template alone and override its repository from the parent values file.
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cd "$SANDBOX"
# undo the template fix, use a values override instead
cp "$LEVEL_DIR/broken/shop-search/charts/indexer/templates/deployment.yaml" shop-search/charts/indexer/templates/deployment.yaml
cat >> values/shop-search.yaml <<'YAML'
indexer:
  image:
    repository: localhost:5001/m10-registry-migration/indexer
YAML
bash deploy-all.sh
