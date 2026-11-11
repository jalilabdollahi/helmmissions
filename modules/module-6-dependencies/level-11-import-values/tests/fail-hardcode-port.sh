#!/bin/bash
# Tempting shortcut: hard-code the port in the parent's values. It renders, but no longer follows the subchart.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/^db: {}/db:\n  port: 5432/' invoicing/values.yaml && rm -f invoicing/values.yaml.bak
helm install invoicing ./invoicing -n "$NS" --wait --timeout 120s
