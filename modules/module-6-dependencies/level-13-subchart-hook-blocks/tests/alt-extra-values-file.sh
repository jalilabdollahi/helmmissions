#!/bin/bash
# Valid alternative: use YAML in a second values file (-f) instead of editing values.yaml.
set -euo pipefail
source "$HM_LIB"

cat > migrator-values.yaml <<'YAML'
schema-migrator:
  database:
    host: orders-db.helmissions.svc.cluster.local
YAML
helm upgrade checkout ./checkout -n "$NS" -f migrator-values.yaml --wait --timeout 120s
