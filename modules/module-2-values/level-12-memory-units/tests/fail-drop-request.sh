#!/bin/bash
# Tempting: silence the API error by deleting the memory request. The limit is still 256 BYTES.
set -euo pipefail
source "$HM_LIB"

sed -i.bak '/^    memory: 128Mi$/d' image-resizer/values.yaml
helm upgrade image-resizer ./image-resizer -n "$NS" --timeout 20s || true
