# Uninstall Leaves A Mess — Walkthrough

1. Confirm the leak and its origin:
   ```bash
   kubectl get pvc -n helmissions                        # exports-scratch is still there
   helm get manifest exports -n helmissions              # (no release any more) - or: helm template exports ./export-batch
   cat export-batch/templates/scratch-volume-job.yaml    # post-install Job POSTs the PVC to the API
   ```
2. Helm only deletes what is in the release manifest. The PVC was made by a Job, so nothing removes it.
3. Add `export-batch/templates/scratch-cleanup-job.yaml`: a Job annotated `"helm.sh/hook": post-delete` (with
   `before-hook-creation,hook-succeeded` delete policy) that uses the `<release>-volumes` ServiceAccount
   and sends `DELETE .../persistentvolumeclaims/<release>-scratch` to the API (treat 404 as success).
   The ServiceAccount, Role (it already allows `delete`) and RoleBinding are hooks that are not deleted on uninstall, so
   they are still there when the post-delete Job runs.
4. Remove the volume that was leaked earlier and test the full cycle:
   ```bash
   kubectl delete pvc exports-scratch -n helmissions
   helm install exports ./export-batch -n helmissions --wait
   kubectl get pvc -n helmissions
   helm uninstall exports -n helmissions
   kubectl get pvc -n helmissions        # empty
   ```
5. Run `check`.
