#!/bin/bash
# Valid: turn the prose into a Helm template comment, which renders to nothing.
set -euo pipefail
source "$HM_LIB"

f="$SANDBOX/helpdesk/templates/usage-notes.yaml"
{ echo '{{- /*'; cat "$f"; echo '*/ -}}'; } >"$f.new" && mv "$f.new" "$f"
helm install helpdesk ./helpdesk -n "$NS" --wait --timeout 120s
