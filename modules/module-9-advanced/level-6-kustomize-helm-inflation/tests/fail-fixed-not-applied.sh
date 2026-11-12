#!/bin/bash
# Partial fix: kustomization repaired and verified, but never applied to the cluster.
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/platform/kustomization.yaml" platform/kustomization.yaml
kubectl kustomize --enable-helm platform >/dev/null
