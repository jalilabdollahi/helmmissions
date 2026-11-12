#!/bin/bash
# Tempting hotfix: patch the live Service selector; the chart still has the hand-written selector.
set -euo pipefail
source "$HM_LIB"

kubectl patch svc payments -n "$NS" --type=merge -p '{"spec":{"selector":{"app":null,"app.kubernetes.io/name":"payments","app.kubernetes.io/instance":"payments"}}}'
