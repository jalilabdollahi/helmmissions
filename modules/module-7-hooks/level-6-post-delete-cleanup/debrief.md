# Uninstall Leaves A Mess

## What broke
The `export-batch` chart gets its staging volume from a `post-install` Job that creates a PVC through the Kubernetes API.
The PVC is therefore not in the release manifest, and neither is it a hook resource Helm tracks. `helm uninstall` removes
what is in the manifest (Deployment, Service) and nothing else, so each uninstalled environment left a PVC behind.

## Why Helm behaves this way
Helm's bookkeeping is the stored manifest of each release revision. Uninstall deletes exactly those objects and runs the
delete-phase hooks: `pre-delete` before anything is removed and `post-delete` after the release resources are gone. Objects
created by controllers, operators, Jobs or humans at runtime are invisible to Helm. Hook resources are not deleted by
uninstall either, unless their `hook-delete-policy` says so. That is also why the ServiceAccount, Role and RoleBinding of the
hooks are still around when the `post-delete` Job runs: they were created as hooks at install time and survive the uninstall.
Helm waits for delete hooks to finish, and a failed one makes the uninstall report an error.

## The fix
Add a Job with `"helm.sh/hook": post-delete` that deletes `<release>-scratch` with the hook ServiceAccount. A `pre-delete` hook
also works; `post-delete` is the natural choice for "clean up after the release has gone". A completely different
design also fixes the leak: declare the PVC in `templates/` so that Helm owns it. Keep in mind that deleting a PVC
deletes the data, so clean-up hooks should only touch scratch data.

## In real life
Leaked PVCs cost money and fill quotas, and they go unnoticed until the cloud bill arrives or a name collides on the
next install. Typical leaks: PVCs from StatefulSet volumeClaimTemplates (Kubernetes never deletes those), buckets and
DNS records created by Jobs, secrets generated at runtime. Decide explicitly which of these must survive an uninstall
and which must not, and encode the decision in the chart.

## Commands worth remembering
- `helm uninstall <rel> --timeout 2m` — also waits for delete hooks
- `kubectl get pvc,pv` — find leftovers
- `helm get hooks <rel>` — which hooks and phases a release has
- `kubectl get pvc -l app.kubernetes.io/instance=<rel>` — find what a release created, when it was labelled

## Common mistakes
- Deleting the leaked PVC by hand: it works for this one release and the next uninstall leaks again.
- Expecting `hook-delete-policy` on the create Job to remove what the Job created (it only deletes the Job).
- Making the cleanup depend on resources that uninstall already removed, such as a ServiceAccount that is a regular release resource.

## Helm 3 vs Helm 4
Same semantics in both: `helm uninstall` runs the delete hooks and waits for them, and `--timeout` bounds the wait. The only visible
difference is the wording of failures when a delete hook fails.
