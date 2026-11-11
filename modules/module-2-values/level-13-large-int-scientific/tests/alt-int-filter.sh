#!/bin/bash
# Valid alternative: `int` instead of `int64`, written with printf.
set -euo pipefail
source "$HM_LIB"

sed 's/{{ .Values.maxUploadBytes | quote }}/{{ printf "%d" (int .Values.maxUploadBytes) | quote }}/' upload-proxy/templates/configmap.yaml > upload-proxy/configmap.new
mv upload-proxy/configmap.new upload-proxy/templates/configmap.yaml
helm upgrade upload-proxy ./upload-proxy -n "$NS" --wait --timeout 120s
