# Rolled Back But Still Broken - Walkthrough

1. Compare configuration and running pods:
   ```bash
   kubectl get configmap edge-throttle-config -n helmissions -o jsonpath='{.data}'   # RATE_LIMIT 100
   kubectl exec -n helmissions deploy/edge-throttle -- env | grep -E 'RATE|BURST'    # RATE_LIMIT=1
   helm history edge-throttle -n helmissions                                         # 3  Rollback to 1
   ```
2. The Deployment's pod template is identical in revisions 1 and 3, so nothing restarted. The pods that exist
   were started by a manual `rollout restart` while the bad ConfigMap was live.
3. Make config changes roll the pods. In `edge-throttle/templates/deployment.yaml`, under
   `spec.template.metadata`:
   ```yaml
   annotations:
     checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
   ```
4. Upgrade (the annotation itself changes the template, so the pods restart now):
   ```bash
   helm upgrade edge-throttle ./edge-throttle -n helmissions --wait
   ```
5. Verify: `curl` through the Service shows `rate_limit=100`. Run `check`.
