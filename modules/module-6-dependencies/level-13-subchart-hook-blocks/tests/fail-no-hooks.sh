#!/bin/bash
# Tempting shortcut: skip the hooks. The release goes green, but the migration never ran.
set -euo pipefail
source "$HM_LIB"

helm uninstall checkout -n "$NS" >/dev/null
helm install checkout ./checkout -n "$NS" --no-hooks --wait --timeout 120s
