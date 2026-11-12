#!/bin/bash
set -euo pipefail
NS="${NS:-helmissions}"
cd "$(dirname "$0")"
for svc in ingest rollup alerts; do
  helm upgrade --install "telemetry-$svc" ./telemetry -n "$NS" -f "values/$svc.yaml" --wait --timeout 60s
done
