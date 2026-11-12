#!/bin/bash
# Valid alternative: pick the API version from .Capabilities so one chart serves old and new clusters.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
python3 - <<'PY'
p='inventory-service/templates/pdb.yaml'
s=open(p).read().replace('apiVersion: policy/v1','apiVersion: {{ if .Capabilities.APIVersions.Has "policy/v1" }}policy/v1{{ else }}policy/v1beta1{{ end }}')
open(p,'w').write(s)
p='inventory-service/templates/hpa.yaml'
s=open(p).read().replace('apiVersion: autoscaling/v2','apiVersion: {{ if .Capabilities.APIVersions.Has "autoscaling/v2" }}autoscaling/v2{{ else }}autoscaling/v2beta2{{ end }}')
open(p,'w').write(s)
PY
helm upgrade --install inventory ./inventory-service -n "$NS" --wait --timeout 120s
