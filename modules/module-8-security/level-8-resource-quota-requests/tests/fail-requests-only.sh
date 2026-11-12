#!/bin/bash
# Partial fix: requests without limits — the quota also constrains limits.cpu/limits.memory.
set -euo pipefail
source "$HM_LIB"

python3 - <<'PY'
p='search-indexer/values.yaml'
s=open(p).read().replace('resources: {}','resources:\n  requests:\n    cpu: 50m\n    memory: 64Mi')
open(p,'w').write(s)
PY
helm upgrade search-indexer ./search-indexer -n "$NS" --timeout 30s || true
sleep 5
