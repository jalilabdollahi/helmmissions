# Every Deploy Scales To 2 - Walkthrough

1. Reproduce:
   ```bash
   kubectl scale deployment/thumbnail-svc -n helmissions --replicas=5
   bash ci/deploy.sh
   kubectl get deployment thumbnail-svc -n helmissions      # back to 2/2
   ```
2. Look at the chart: `thumbnail-svc/templates/deployment.yaml` has `replicas: {{ .Values.replicaCount }}`
   unconditionally, and `templates/hpa.yaml` is also installed when `autoscaling.enabled` is true. Two owners
   fight over the same field and Helm's value wins on every deploy.
3. Let the HPA own the field when it is enabled:
   ```yaml
   {{- if not .Values.autoscaling.enabled }}
   replicas: {{ .Values.replicaCount }}
   {{- end }}
   ```
4. Deploy and verify:
   ```bash
   bash ci/deploy.sh
   kubectl scale deployment/thumbnail-svc -n helmissions --replicas=5
   bash ci/deploy.sh
   kubectl get deployment thumbnail-svc -n helmissions      # still 5
   ```
   (The first deploy after the fix removes `replicas` from the manifest, which Kubernetes treats as "default 1" for
   that one upgrade; from then on deploys leave the field alone.)
5. Run `check`.
