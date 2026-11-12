# The Secret Isn't There Yet

## What broke
`payroll-api` bootstraps its database role in a pre-install Job that reads the `payroll-db` Secret through `envFrom`. The Secret is a regular chart
template. The install order is: render everything, run `pre-install` hooks, wait for them, and only then create regular resources. The Job's pod could
not start (`CreateContainerConfigError: secret "payroll-db" not found`), the Job sat there until its 30-second deadline, and the install failed.
The Deployment, which uses the same Secret, was never created either.

## Why Helm behaves this way
Hooks exist to run things *around* the creation of the release's resources, so Helm never creates normal resources before the pre-install hooks are done.
Anything a pre-install hook depends on (Secrets, ConfigMaps, ServiceAccounts, RBAC, even PVCs) therefore has to be part of the hook phase itself:
annotate it as a hook with a lower weight than the Job that uses it. Hooks of one phase run in ascending weight order and each is waited for. A
non-workload hook is "ready" as soon as it has been created, so the Job starts right after it. Hook resources are not part of the release manifest,
which is the price you pay.

## The fix
Mark the Secret `helm.sh/hook: pre-install,pre-upgrade` with weight `-10`, and keep the policy `before-hook-creation`. With `hook-succeeded` it
would be deleted right after creation and the application could not mount it. The alternative is to restructure: pass the credentials to the Job through
chart values instead of a Secret that does not exist yet, or create the database bootstrap as a post-install step that the app does not depend on.

## In real life
Because hook resources live outside the manifest, `helm uninstall` leaves the Secret behind, `helm get manifest` does not show it, and drift detection
tools do not see it. Many teams therefore prefer creating shared prerequisites (Secrets, DB credentials) *outside* the release (external-secrets, a separate
bootstrap chart, a platform-managed Secret) and referencing them by name. When you use hooks for prerequisites, document the trade-off in the chart.

## Commands worth remembering
- `kubectl describe pod <hook-pod>` — `CreateContainerConfigError` and `FailedMount` explain missing Secrets and ConfigMaps
- `helm get hooks <rel>` vs `helm get manifest <rel>` — where each object landed
- `helm install --timeout 1m` — make an unresolvable hook fail fast
- `kubectl get secret <name> -o yaml` — verify what the hook created

## Common mistakes
- Creating the Secret by hand before the install: Helm refuses to adopt an object it did not create (`invalid ownership metadata`).
- Using `hook-succeeded` on a resource that the application needs later.
- Raising the Job's weight or timeout: the regular Secret still does not exist during any pre-install hook.

## Helm 3 vs Helm 4
Same order of events in both versions. Helm 4 waits for hooks even when `--wait` is omitted, so a hook Job blocked on a missing object keeps the install waiting until the
`--timeout` (default 5 minutes) or the Job's own deadline, whichever is first.
