# 403 From The API — Walkthrough

1. Read the log:
   ```bash
   kubectl logs deploy/flag-sync -n helmissions
   # list pods -> 200, list configmaps -> 403
   ```
2. Confirm with impersonation:
   ```bash
   kubectl auth can-i list pods       -n helmissions --as=system:serviceaccount:helmissions:flag-sync   # yes
   kubectl auth can-i list configmaps -n helmissions --as=system:serviceaccount:helmissions:flag-sync   # no
   ```
3. Open `flag-sync/templates/role.yaml`: the Role grants `get/list/watch` on `pods` only.
4. Add one more rule to that Role:
   ```yaml
   - apiGroups: [""]
     resources: ["configmaps"]
     verbs: ["get", "list", "watch"]
   ```
   (`["list"]` alone is enough too.) Do not use `*`, do not add write verbs, do not touch the binding.
5. `helm upgrade flag-sync ./flag-sync -n helmissions --wait`. The ServiceAccount token is read fresh by the
   syncer, so the pod turns Ready without a restart.
6. Verify: `kubectl auth can-i list secrets -n helmissions --as=...` must still be `no`. Run `check`.
