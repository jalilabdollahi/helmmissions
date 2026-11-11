#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cat > values-dns.yaml <<'YAML'
dnsSearch:
  - payments.svc.cluster.local
  - corp.internal
YAML
helm install mesh-client ./mesh-client -n "$NS" -f values-dns.yaml --wait --timeout 120s
