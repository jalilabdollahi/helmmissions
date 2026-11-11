#!/bin/bash
# Guesses `service.port` (a common convention) - this chart does not read it, so the Service stays on 80.
set -euo pipefail
source "$HM_LIB"

printf 'service:\n  port: 9100\n' >"$SANDBOX/probe-values.yaml"
helm install node-probe vendor/node-probe-0.4.2.tgz -n "$NS" -f probe-values.yaml --wait --timeout 120s
