#!/bin/bash
# Alternative: edit the broken file in place, removing only the right-hand trim marker.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/{{ .Values.replicaCount -}}/{{ .Values.replicaCount }}/' "$SANDBOX/thumbnailer/templates/deployment.yaml"
rm -f "$SANDBOX/thumbnailer/templates/deployment.yaml.bak"
helm install thumbs ./thumbnailer -n "$NS" --wait --timeout 120s
