#!/bin/bash
# Shortcut: roll everything back to the old working revision; version 2.0 never ships.
set -euo pipefail
source "$HM_LIB"
for s in ingest rollup alerts; do helm rollback "telemetry-$s" 1 -n "$NS" --wait --timeout 60s; done
