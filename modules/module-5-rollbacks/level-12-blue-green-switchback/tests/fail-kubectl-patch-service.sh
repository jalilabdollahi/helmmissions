#!/bin/bash
# Tempting wrong fix: patch the Service selector by hand. Traffic recovers, but Helm still says green.
set -euo pipefail
source "$HM_LIB"

kubectl patch service ticket-booking -n "$NS" -p '{"spec":{"selector":{"color":"blue"}}}'
