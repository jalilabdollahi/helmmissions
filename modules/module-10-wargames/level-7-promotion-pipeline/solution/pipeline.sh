#!/bin/bash
# Promotion pipeline: dev -> staging -> prod
set -euo pipefail
cd "$(dirname "$0")"
TAG="$(cat VERSION)"
DEV_NS=helmissions-dev
STG_NS=helmissions-staging
PROD_NS=helmissions

deploy() {  # deploy <namespace> <release> <values-file> [extra helm args]
  helm upgrade --install "$2" ./billing -n "$1" --create-namespace -f "$3" --wait --timeout 30s "${@:4}"
}

echo "== dev"
deploy "$DEV_NS" billing-dev values/dev.yaml --set image.tag="$TAG"

echo "== staging"
deploy "$STG_NS" billing-staging values/staging.yaml --set image.tag="$TAG"
PROMOTED="$(helm get values billing-staging -n "$STG_NS" -o json 2>/dev/null | jq -r '.image.tag // empty')"

echo "== prod (promoting build '$PROMOTED')"
deploy "$PROD_NS" billing values/prod.yaml --set image.tag="$PROMOTED"
