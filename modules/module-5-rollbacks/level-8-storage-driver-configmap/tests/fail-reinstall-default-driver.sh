#!/bin/bash
# Tempting wrong fix: helm can't see a release, so install a fresh one. It lands in Secret storage and the
# pipeline's real release stays on its broken revision 2.
set -euo pipefail
source "$HM_LIB"

helm install audit-gateway "$LEVEL_DIR/assets/audit-gateway" -n "$NS" --wait --timeout 90s
