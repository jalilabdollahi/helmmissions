#!/bin/bash
# Tempting workaround: pass the port with --set (an int64 prints fine); the chart still breaks for values files.
set -euo pipefail
source "$HM_LIB"

helm upgrade ingest ./ingest -n "$NS" --set port=8080 --wait --timeout 120s
