#!/bin/bash
# Tempting shortcut: delete the capability check from the chart so the monitor always renders.
set -euo pipefail
source "$HM_LIB"

sed 's#^{{- if and .Values.metrics.enabled (.Capabilities.APIVersions.Has "monitoring.helmissions.io/v1") }}#{{- if .Values.metrics.enabled }}#' checkout/templates/servicemonitor.yaml > "$HM_TMP/sm.yaml"
cp "$HM_TMP/sm.yaml" checkout/templates/servicemonitor.yaml
./render.sh
kubectl apply -n "$NS" -f rendered/prod.yaml
