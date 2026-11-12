#!/bin/bash
# Tempting hotfix: patch the live Service. The release and the chart still say 8080.
set -euo pipefail
source "$HM_LIB"

kubectl patch svc inventory -n "$NS" --type=json -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":80}]'
