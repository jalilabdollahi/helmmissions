#!/bin/bash
# Helm post-renderer: rendered manifests arrive on stdin, patched manifests must leave on stdout.
set -euo pipefail
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cp "$HELM_PLUGIN_DIR/kustomization.yaml" "$work/kustomization.yaml"
cat > "$work/all.yaml"
kubectl kustomize "$work"
