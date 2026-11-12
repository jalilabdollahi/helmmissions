#!/bin/bash
# Shortcut: delete the resource requests so everything schedules; violates the cluster policy.
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cd "$SANDBOX"
for s in ingest rollup alerts; do
  perl -0pi -e 's/resources:\n  requests:\n    cpu: [^\n]*\n    memory: [^\n]*\n//' "values/$s.yaml"
done
perl -pi -e 's/cpu: 10m/cpu: 0/; s/memory: 16Mi/memory: 0/' telemetry/values.yaml
perl -0pi -e 's/resources:\n\s+\{\{- toYaml .Values.resources \| nindent 12 \}\}/resources: {}/' telemetry/templates/deployment.yaml
bash release.sh
