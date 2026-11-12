#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
helm upgrade --install orders-api ./orders-api -n helmissions-api --create-namespace --wait --timeout 60s
helm upgrade --install orders-web ./orders-web -n helmissions-web --create-namespace --wait --timeout 60s
