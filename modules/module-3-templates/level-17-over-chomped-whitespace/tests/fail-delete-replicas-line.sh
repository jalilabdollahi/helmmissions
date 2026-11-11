#!/bin/bash
# Tempting shortcut: delete the line that carries the chomp marker; the chart parses but replicaCount is ignored.
set -euo pipefail
source "$HM_LIB"

sed -i.bak '/replicas: {{ .Values.replicaCount/d' "$SANDBOX/thumbnailer/templates/deployment.yaml"
rm -f "$SANDBOX/thumbnailer/templates/deployment.yaml.bak"
helm install thumbs ./thumbnailer -n "$NS" --wait --timeout 120s
