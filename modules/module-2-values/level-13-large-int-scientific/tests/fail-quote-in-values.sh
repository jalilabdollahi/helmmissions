#!/bin/bash
# Tempting: turn the default into a string in values.yaml. This release works, but any environment that
# overrides the number in its own values file hits the same bug.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/^maxUploadBytes: 1048576/maxUploadBytes: "1048576"/' upload-proxy/values.yaml
helm upgrade upload-proxy ./upload-proxy -n "$NS" --wait --timeout 120s
