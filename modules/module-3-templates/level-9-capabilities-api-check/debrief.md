# Wrong Ingress API

## What broke
The helper asked `.Capabilities.APIVersions.Has "networking.k8s.io/v1/ingress"` - with a lower-case kind. The check
is an exact string comparison against the list of `group/version/Kind` strings that Helm collected from the cluster,
so it was always false and the template fell back to `networking.k8s.io/v1beta1`. That API was removed in
Kubernetes 1.22, so the API server answered `no matches for kind "Ingress" in version "networking.k8s.io/v1beta1"`.

## Why Helm behaves this way
`.Capabilities` is built from the cluster at install/upgrade time (API discovery) so charts can adapt to what the
target cluster supports. `Has` accepts `group/version` (does the cluster serve it at all?) or `group/version/Kind`
(is this specific kind there?), both case-sensitive. It returns a plain boolean: a typo is just "not found", there is
no warning. Also note the difference between commands: `helm install`/`upgrade` and `helm template --dry-run=server` (`--validate` on Helm 3) ask the cluster, while plain `helm template` (and `--dry-run=client`) uses a built-in default list
that does not include modern Ingress - so an offline render can disagree with the live install.

## The fix
Fix the string to `networking.k8s.io/v1/Ingress`. A version comparison (`semverCompare ">=1.19-0" .Capabilities.KubeVersion.Version`)
also works and is popular because it does not depend on discovery, but it breaks on clusters whose version string
carries vendor suffixes unless the range ends in `-0`.

## In real life
Compatibility branches written for 1.14-1.18 clusters linger for years in forked charts. A wrong check passes review
because nobody has a cluster old enough to hit the other branch. After a Kubernetes upgrade removes an API
(Ingress v1beta1, PodSecurityPolicy, batch/v1beta1 CronJob, policy/v1beta1 PDB), everything that still renders the old
one fails - or worse, renders it and the apply is rejected only in production. Run `helm template --dry-run=server` (or
kubeconform with the target version) in CI against the Kubernetes version you actually run.

## Commands worth remembering
- `kubectl api-resources --api-group=networking.k8s.io` - what the cluster serves
- `helm template ./chart --dry-run=server` (Helm 3: `--validate`) - render with the cluster's capabilities
- `helm template ./chart --api-versions networking.k8s.io/v1/Ingress --kube-version 1.30.0` - simulate offline

## Common mistakes
- Turning the Ingress off in values: the install passes but the portal has no external route.
- Trusting plain `helm template` output when debugging capability checks.
- Removing the `else` branch and the v1beta1 manifest while the chart still claims support for old clusters in `kubeVersion`.

## Helm 3 vs Helm 4
Helm 4 deprecates `helm template --validate` in favour of `--dry-run=server`; Helm 3 only has `--validate`.
Behaviour of `.Capabilities` is the same. Helm 4 installs with server-side apply, but the failure shown here is raised
earlier, while Helm builds the object list from the manifest (REST mapping not found). On both, a failed first install
leaves a failed release behind unless the failure happens at render time.
