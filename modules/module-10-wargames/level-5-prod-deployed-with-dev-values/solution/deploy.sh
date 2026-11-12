#!/bin/bash
# Usage: deploy.sh dev|prod
ENVIRONMENT="${1:?usage: deploy.sh dev|prod}"
cd "$(dirname "$0")"

case "$ENVIRONMENT" in
  dev)
    NAMESPACE=helmissions-dev
    RELEASE=invoice-dev
    VALUES=values-dev.yaml
    ;;
  prod)
    NAMESPACE=helmissions
    RELEASE=invoice
    VALUES=values-prod.yaml
    ;;
  *)
    echo "unknown environment: $ENVIRONMENT"; exit 2
    ;;
esac

helm upgrade --install "$RELEASE" ./invoice -n "$NAMESPACE" --create-namespace \
  --reset-values -f "$VALUES" --wait --timeout 60s
