#!/bin/bash
# Tempting: escape the comma. That yields ONE string "a,b", not a list of two.
set -euo pipefail
source "$HM_LIB"

helm install mesh-client ./mesh-client -n "$NS" \
  --set 'dnsSearch=payments.svc.cluster.local\,corp.internal' --wait --timeout 60s || true
