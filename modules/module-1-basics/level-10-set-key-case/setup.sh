#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install billing "$SANDBOX/billing" -n "$NS" --wait --timeout 120s >/dev/null
# The colleague's command: wrong key case. Helm accepts any key, so this "succeeds".
helm upgrade billing "$SANDBOX/billing" -n "$NS" --set replicacount=4 --wait --timeout 120s >/dev/null
[ "$(hm_release_revision billing)" = 2 ] || { echo "setup: expected revision 2"; exit 1; }
[ "$(hm_jsonpath deployment/billing '{.spec.replicas}')" = 1 ] || { echo "setup: deployment should still have 1 replica"; exit 1; }
