# Lines Glued Together - Walkthrough

1. `helm install thumbs ./thumbnailer -n helmissions` fails with a YAML error on line 6 of the rendered
   deployment.yaml (the line number refers to the rendered text, not the template).
2. `helm template thumbs ./thumbnailer --debug` prints the broken manifest: `replicas: 2revisionHistoryLimit: 2`.
3. In the template the line reads `replicas: {{ .Values.replicaCount -}}`. The `-}}` trims everything up to the next
   non-space character: the newline and the two spaces before `revisionHistoryLimit`.
4. Remove the dash: `replicas: {{ .Values.replicaCount }}`.
5. `helm template thumbs ./thumbnailer | head -15` - the keys are on separate lines again. Then
   `helm install thumbs ./thumbnailer -n helmissions --wait`.
