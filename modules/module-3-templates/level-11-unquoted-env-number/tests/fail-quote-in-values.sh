#!/bin/bash
# Tempting workaround: quote the number in values.yaml. The template still prints it bare, so it is still a number.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/^listenPort: 2525/listenPort: "2525"/' "$SANDBOX/smtp-relay/values.yaml"
rm -f "$SANDBOX/smtp-relay/values.yaml.bak"
helm install relay ./smtp-relay -n "$NS" --timeout 30s || true
