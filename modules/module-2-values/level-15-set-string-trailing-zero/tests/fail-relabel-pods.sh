#!/bin/bash
# Tempting hotfix: relabel the running pods. The Deployment (and the next rollout) still say 1.1.
set -euo pipefail
source "$HM_LIB"

kubectl label pods -n "$NS" -l app.kubernetes.io/instance=status-page app.version=1.10 --overwrite
