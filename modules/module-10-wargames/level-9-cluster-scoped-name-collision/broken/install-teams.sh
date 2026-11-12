#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
helm upgrade --install team-a ./collector -n helmissions-team-a --create-namespace -f values/team-a.yaml --wait --timeout 60s
helm upgrade --install team-b ./collector -n helmissions-team-b --create-namespace -f values/team-b.yaml --wait --timeout 60s
