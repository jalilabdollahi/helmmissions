# The Invisible Release - Walkthrough

1. Notice the contradiction: the Deployment has Helm labels, `ci/deploy.log` shows revision 2, but
   `helm list -n helmissions` is empty.
2. Look at where Helm keeps its records:
   ```bash
   kubectl get configmaps,secrets -n helmissions
   # configmap/sh.helm.release.v1.audit-gateway.v1 ... v2   <-- the release records
   cat ci/pipeline.env                                        # export HELM_DRIVER=configmap
   ```
3. Use the same storage driver:
   ```bash
   export HELM_DRIVER=configmap
   helm list -n helmissions
   helm history audit-gateway -n helmissions
   helm get values audit-gateway -n helmissions     # extraArgs: [--retention-days=30] <- unknown flag
   ```
4. Roll back (still with the driver set!):
   ```bash
   helm rollback audit-gateway 1 -n helmissions --wait
   ```
5. Verify the pod is Ready and that `unset HELM_DRIVER; helm list -n helmissions` is still empty (no second
   release). Run `check`.
