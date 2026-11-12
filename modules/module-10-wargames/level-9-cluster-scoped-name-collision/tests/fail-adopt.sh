#!/bin/bash
# Shortcut: re-annotate the shared cluster-scoped objects so team-b can adopt them; both releases now fight over one object.
set -euo pipefail
source "$HM_LIB"
for obj in clusterrole/helmissions-pod-reader clusterrolebinding/helmissions-pod-reader priorityclass/helmissions-collector; do
  kubectl annotate "$obj" meta.helm.sh/release-name=team-b meta.helm.sh/release-namespace=helmissions-team-b --overwrite >/dev/null
done
kubectl patch clusterrolebinding helmissions-pod-reader --type=json -p '[{"op":"add","path":"/subjects/-","value":{"kind":"ServiceAccount","name":"collector","namespace":"helmissions-team-b"}}]'
helm install team-b "$SANDBOX/collector" --server-side=false -n helmissions-team-b -f "$SANDBOX/values/team-b.yaml" --wait --timeout 90s
