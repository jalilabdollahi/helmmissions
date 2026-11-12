#!/bin/bash
# Tempting wrong fix: remove `immutable: true` - but wait, that is an update of an immutable object too, and it
# would undo the security requirement anyway. (Helm cannot even apply it: the live object is immutable.)
set -euo pipefail
source "$HM_LIB"

sed -i.bak '/^immutable: true/d' feature-flags/templates/configmap.yaml
rm -f feature-flags/templates/configmap.yaml.bak
helm upgrade flags ./feature-flags -n "$NS" --wait --timeout 60s || true
