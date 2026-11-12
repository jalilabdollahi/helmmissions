#!/bin/bash
# Valid alternative: make the PVC an ordinary chart resource (Helm then owns and deletes it) and drop the Job.
set -euo pipefail
source "$HM_LIB"

kubectl delete pvc exports-scratch -n "$NS"
rm "$SANDBOX/export-batch/templates/scratch-volume-job.yaml"
cat > "$SANDBOX/export-batch/templates/scratch-pvc.yaml" <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .Release.Name }}-scratch
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: {{ .Values.scratch.size }}
YAML
helm install exports ./export-batch -n "$NS" --timeout 90s
helm uninstall exports -n "$NS" --timeout 90s
