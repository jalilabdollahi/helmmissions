#!/bin/bash
# Pipeline step used by the payments team: deploy the gateway chart that sits next to this ci/ directory.
# NAMESPACE and RELEASE can be overridden by the pipeline for preview environments.
set -euo pipefail
cd "$(dirname "$0")/.."
NAMESPACE="${NAMESPACE:-helmissions}"
RELEASE="${RELEASE:-payments-gateway}"

helm upgrade --install "$RELEASE" ./payments-gateway -n "$NAMESPACE" --create-namespace --timeout 2m
