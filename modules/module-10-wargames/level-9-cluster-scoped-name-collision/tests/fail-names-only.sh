#!/bin/bash
# Partial fix: the three names are made unique, but the binding still names team A's ServiceAccount namespace.
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cd "$SANDBOX"
perl -pi -e 's/namespace: \{\{ .Release.Namespace \}\}$/namespace: helmissions-team-a/' collector/templates/rbac.yaml
helm upgrade --install team-a ./collector -n helmissions-team-a -f values/team-a.yaml --wait --timeout 60s
helm upgrade --install team-b ./collector -n helmissions-team-b -f values/team-b.yaml --wait --timeout 30s || true
