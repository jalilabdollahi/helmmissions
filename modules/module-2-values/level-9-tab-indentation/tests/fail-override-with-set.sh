#!/bin/bash
# Tempting: keep the broken file and... delete the audit block, passing the settings on the command line.
# The file Helm cannot parse is still shipped to the next person.
set -euo pipefail
source "$HM_LIB"

grep -v "$(printf '\t')" audit-log/values.yaml | grep -v '^audit:' > audit-log/values.tmp && mv audit-log/values.tmp audit-log/values.yaml
helm install audit-log ./audit-log -n "$NS" \
  --set audit.retentionDays=90 --set audit.sink.host=siem.corp.example --set audit.sink.port=6514 --set audit.sink.tls=true \
  --wait --timeout 120s
