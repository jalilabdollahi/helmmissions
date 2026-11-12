# GitOps Render Lost The ServiceMonitor

## What broke
The pipeline renders charts with `helm template` on a runner without cluster access. The chart wraps its ServiceMonitor in
`.Capabilities.APIVersions.Has "monitoring.helmissions.io/v1"`, which is the correct way to support clusters with and without
the monitoring CRD. But offline, `Has` is always false for CRD groups, so the template quietly rendered to nothing: no error, no
warning, a green pipeline and an empty dashboard.

## Why Helm behaves this way
`.Capabilities` describes the cluster a release will run on. `helm install` and `helm upgrade` build it by discovery against the live
API server. `helm template` is client-only by default: it fills Capabilities with the Kubernetes version and the API list compiled into
Helm, which has no knowledge of your CRDs. Conditionals on Capabilities therefore flip between `template` and `install`, and an
`if` that fails produces empty output, not an error. You control the offline view with `--api-versions group/version` (repeatable),
`--kube-version`, or by switching to `--dry-run=server`, which asks a real cluster (and also runs install-time checks such as object ownership). Note that `--api-versions` expects `group/version`
(`monitoring.helmissions.io/v1`); a `group/version/Kind` entry only matches the `Kind` check.

## The fix
Declare the cluster's extra APIs in the render step (`--api-versions monitoring.helmissions.io/v1`), re-render, and apply what the script
emits. Keep the guard in the chart: it is what lets the same chart install on a cluster without the CRD. Never patch the rendered output by hand —
the next CI run will regenerate it without your edit.

## In real life
Argo CD, Flux and "rendered manifests" repositories all render offline, so every Capabilities-dependent chart (Ingress API versions,
PodDisruptionBudget, HPA v2, ServiceMonitor, Gateway API) can differ between what CI renders and what the cluster would render. Typical
defences: pass `--kube-version` and `--api-versions` for each target environment from a config file, diff the rendered output against `helm
template --dry-run=server` in a nightly job, or install CRDs first and render per cluster. Argo CD has `kubeVersion` and `apiVersions` settings
for exactly this. Prefer values flags (`metrics.serviceMonitor.enabled`) over auto-detection when you can; use Capabilities for compatibility, not for turning features on.

## Commands worth remembering
- `helm template ... --api-versions group/version --kube-version 1.30.0` — emulate cluster capabilities offline
- `helm template ... --dry-run=server` — render with a real cluster's capabilities (needs access)
- `kubectl api-versions | grep monitoring` — what the cluster really offers
- `diff <(helm template ...) rendered/prod.yaml` — detect drift in CI

## Common mistakes
- Appending the missing object to the rendered file or applying a hand-written copy: CI overwrites it next run.
- Deleting the `Has` guard so the monitor always renders: the chart then fails on clusters without the CRD.
- Passing `group/version/Kind` to `--api-versions` and wondering why a `group/version` check still fails.

## Helm 3 vs Helm 4
Both versions behave the same offline. `helm template --validate` (Helm 3) is deprecated in Helm 4 in favour of `--dry-run=server`,
and Helm 4's default `helm template` still reports a built-in Kubernetes version rather than the cluster's unless you pass `--kube-version`.
