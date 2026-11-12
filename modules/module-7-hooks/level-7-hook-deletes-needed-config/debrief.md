# The Config That Hooked Itself Away

## What broke
The routing-table ConfigMap of `route-gateway` had been given `helm.sh/hook: pre-install,pre-upgrade` and
`hook-delete-policy: hook-succeeded` (copied from a "validate the config first" snippet). Helm created it during the pre-install
phase, immediately considered the hook successful (a ConfigMap has no readiness to wait for) and deleted it. Only then
did the Deployment get created, mounting a ConfigMap that no longer existed. Because the install did not use `--wait`, Helm reported
`deployed` while the pod sat in `ContainerCreating`.

## Why Helm behaves this way
A manifest with a `helm.sh/hook` annotation is taken out of the release's regular manifest. It is managed only by the hook rules:
created at the stated phase, left alone or removed according to `hook-delete-policy`. `helm get manifest` lists the normal
resources, `helm get hooks` the hooks. For Jobs and Pods "succeeded" means the workload finished; for any other kind it is true
as soon as the object has been created, so `hook-succeeded` removes it right away. Hook resources are also not reconciled on later upgrades and are
not removed by `helm uninstall` unless a policy says so.

## The fix
Configuration that the application needs for its entire life is not a hook. Remove the hook annotations so the
ConfigMap is a regular release resource: it is created together with the Deployment, updated on upgrades, listed in
`helm get manifest`, and removed on uninstall. If you really want to validate the config before rolling it out, validate it with a Job
hook that reads a separate copy, or with `helm lint`/`helm template` in CI.

## In real life
Copy-pasted annotations are a classic source of this bug, and the symptom shows up far from the cause: a pod stuck in `ContainerCreating`, a
`deployed` release. Add `--wait` to deploy commands so a hook-eaten dependency fails the deploy, and after any change to hook annotations compare
`helm get manifest` with `helm get hooks` to see where each object landed.

## Commands worth remembering
- `helm get manifest <rel>` / `helm get hooks <rel>` — regular resources versus hooks
- `kubectl describe pod <pod>` — mount and scheduling problems appear under Events
- `helm template <chart> --show-only templates/<file>` — see the annotations that will actually be applied

## Common mistakes
- Recreating the ConfigMap with `kubectl create`: the pod starts, but Helm does not own it and the next upgrade or uninstall will not manage it.
- Removing only the delete policy: the object survives, but it is still a hook (outside the manifest, not reconciled, not removed on uninstall).
- Deploying without `--wait` and trusting a `deployed` status.

## Helm 3 vs Helm 4
Same behaviour in both versions: a non-workload hook resource counts as succeeded as soon as it is created, and `hook-succeeded` deletes it
immediately. Helm 4's default of waiting only for hooks does not wait for the Deployment, which is why this install said `deployed`.
