#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# values.yaml says search.enabled=false, yet the release deploys the search subchart anyway.
helm dependency update "$SANDBOX/helpdesk" >/dev/null
helm install helpdesk "$SANDBOX/helpdesk" -n "$NS" --wait --timeout 120s >/dev/null
hm_assert_status helpdesk deployed
kubectl get deployment helpdesk-ticket-search -n "$NS" >/dev/null 2>&1 \
  || { echo "setup: the search subchart is not running — scenario not reached"; exit 1; }
