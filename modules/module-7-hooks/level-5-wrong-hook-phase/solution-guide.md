# The Migration Ran Too Late — Walkthrough

1. Look at the stuck rollout:
   ```bash
   helm history shipments -n helmissions                   # rev 2 failed: context deadline exceeded
   kubectl get pods,jobs -n helmissions                    # new pod Init:..., no migrate Job
   kubectl logs deploy/shipments -c wait-for-schema -n helmissions
   ```
   The init container of 1.1 refuses to start until ConfigMap `shipments-schema-v2` exists.
2. Find who creates it: `shipment-tracker/templates/migrate-job.yaml`, annotated `"helm.sh/hook": post-upgrade`.
   `post-upgrade` hooks run after the release resources are applied and (with `--wait`) after they are ready, so the Job
   waits for pods that are waiting for the Job.
3. Change the annotation to `"helm.sh/hook": pre-upgrade` so the schema exists before the new Deployment is rolled out.
4. Upgrade:
   ```bash
   helm upgrade shipments ./shipment-tracker -n helmissions --wait
   kubectl get jobs -n helmissions
   kubectl get configmap shipments-schema-v2 -n helmissions -o yaml
   ```
5. Run `check`; it also replays a clean 1.0.0 -> 1.1.0 upgrade in a fresh namespace.
