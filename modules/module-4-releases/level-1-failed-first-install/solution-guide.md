# Born Failed — Walkthrough

1. See what the pipeline left behind:
   ```bash
   helm list -n helmissions --failed
   helm history invoice-api -n helmissions
   ```
   Revision 1 is `failed` and its description holds the API error: `spec.type: Unsupported value: "ClusterIp"`.
2. Render the chart and find the culprit:
   ```bash
   helm template invoice-api ./invoice-api -n helmissions | grep -n "type:"
   ```
   `values.yaml` has `service.type: ClusterIp`. Kubernetes service types are case sensitive: `ClusterIP`.
3. Fix `invoice-api/values.yaml` (`type: ClusterIP`) and run `helm lint ./invoice-api`.
4. Re-installing fails with `cannot reuse a name that is still in use`, because the failed release is
   recorded in the cluster. Upgrade it instead:
   ```bash
   helm upgrade invoice-api ./invoice-api -n helmissions --wait
   ```
   (`helm uninstall invoice-api -n helmissions` followed by `helm install` also works here, since a
   failed first revision has nothing worth keeping.)
5. Verify:
   ```bash
   helm history invoice-api -n helmissions     # rev 1 superseded (failed), rev 2 deployed
   kubectl get pods,svc -n helmissions
   ```
6. Run `check` in the game.
