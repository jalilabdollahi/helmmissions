# The Hotfix That Vanished - Walkthrough

1. Look at the symptom and at what Helm believes:
   ```bash
   kubectl get deploy order-sync -n helmissions -o jsonpath='{.spec.template.spec.containers[0].env}'
   helm get values order-sync -n helmissions --all     # db.poolSize: 5
   helm history order-sync -n helmissions              # 2 revisions - the second one is the log-level change
   ```
2. The 40 from the hotfix exists in no revision: it was applied with `kubectl set env`, so Helm never stored it.
   The pipeline's `helm upgrade` rendered `db.poolSize: 5` from the chart default and the cluster was
   brought back in line with Git.
3. Make the setting durable. In `values-prod.yaml`:
   ```yaml
   db:
     poolSize: 40
   ```
   (Raising the default in `order-sync/values.yaml` also works.)
4. Deploy the way the pipeline does:
   ```bash
   bash ci/deploy.sh
   helm history order-sync -n helmissions      # revision 3, "Upgrade complete"
   ```
5. Verify: `kubectl get deploy ... env` shows 40 and `curl` of the service says `status=ok`.
