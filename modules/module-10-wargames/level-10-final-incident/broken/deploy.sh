#!/bin/bash
# Usage: deploy.sh staging|prod
set -euo pipefail
ENVIRONMENT="${1:?usage: deploy.sh staging|prod}"
cd "$(dirname "$0")"
case "$ENVIRONMENT" in
  staging) NAMESPACE=helmissions-staging; RELEASE=tideline-staging ;;
  prod)    NAMESPACE=helmissions;         RELEASE=tideline ;;
  *) echo "unknown environment: $ENVIRONMENT" >&2; exit 2 ;;
esac
helm upgrade --install "$RELEASE" ./tideline -n "$NAMESPACE" --create-namespace \
  -f values/common.yaml -f "values/$ENVIRONMENT.yaml" --wait --timeout 90s
