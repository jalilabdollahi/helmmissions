# GitOps Render Lost The ServiceMonitor — Walkthrough

1. Reproduce the symptom:
   ```bash
   ./render.sh
   grep -c ServiceMonitor rendered/prod.yaml          # 0
   kubectl get servicemonitors.monitoring.helmissions.io -n helmissions    # none
   ```
2. Read `checkout/templates/servicemonitor.yaml`: it is wrapped in
   `{{- if and .Values.metrics.enabled (.Capabilities.APIVersions.Has "monitoring.helmissions.io/v1") }}`.
3. `helm template` renders client-side. It knows only the API versions built into the Helm binary, not the CRDs of your
   cluster, so `Has` is false and the whole file renders to nothing — no error. (`helm install` asks the cluster, so it works.)
   Prove it: `helm template probe ./checkout --dry-run=server -f env/prod.yaml | grep ServiceMonitor` (a different release name, because `checkout` objects were applied with kubectl and Helm would refuse to adopt them).
4. In CI there is no cluster, so tell the render what the target cluster offers. Edit `render.sh`:
   ```bash
   helm template checkout ./checkout --namespace helmissions -f env/prod.yaml \
     --api-versions monitoring.helmissions.io/v1 > "$OUT"
   ```
5. Regenerate and apply:
   ```bash
   ./render.sh
   grep -A14 'kind: ServiceMonitor' rendered/prod.yaml
   kubectl apply -n helmissions -f rendered/prod.yaml
   kubectl get servicemonitors.monitoring.helmissions.io -n helmissions
   ```
