# Forbidden Inside The Hook — Walkthrough

1. Read the hook's output:
   ```bash
   kubectl logs job/tenants-preflight -n helmissions
   # "configmaps is forbidden: User \"system:serviceaccount:helmissions:default\" cannot list resource \"configmaps\" ..."
   ```
2. The Job does not set `serviceAccountName`, so it runs as `default`, which has no rights. It needs `list` on `configmaps`.
3. Add RBAC to the chart (`templates/preflight-rbac.yaml`): a ServiceAccount, a Role (`configmaps`: `list`) and a RoleBinding.
   Do **not** make them regular templates: those are created after the pre-install hooks and the Job would still be refused.
   Annotate all three as hooks of the same phases with a lower weight than the Job:
   ```yaml
   "helm.sh/hook": pre-install,pre-upgrade
   "helm.sh/hook-weight": "-10"
   "helm.sh/hook-delete-policy": before-hook-creation
   ```
   and set `serviceAccountName: {{ .Release.Name }}-preflight` in `preflight-job.yaml`.
   (Binding the existing `default` account with hook-annotated Role/RoleBinding also works.)
4. Reinstall or upgrade the failed release:
   ```bash
   helm upgrade tenants ./tenant-onboarding -n helmissions --wait
   kubectl logs job/tenants-preflight -n helmissions
   ```
5. Run `check`; it also installs the chart into an empty namespace.
