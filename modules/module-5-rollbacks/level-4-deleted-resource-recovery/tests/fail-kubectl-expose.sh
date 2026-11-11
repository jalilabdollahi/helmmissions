#!/bin/bash
# Tempting wrong fix: recreate the Service by hand.
set -euo pipefail
source "$HM_LIB"

kubectl expose deployment sms-gateway -n "$NS" --port=80 --target-port=http --name=sms-gateway
