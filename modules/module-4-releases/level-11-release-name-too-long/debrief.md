# Must Be No More Than 63 Characters

## What broke
The `fullname` helper built object names as `<release>-<chart>`. With the 45-character release name the
Service name grew to 69 characters. Kubernetes requires Service names (and several other names that become DNS
labels, plus label values) to be at most 63 characters, so the API server rejected the Service.

## Why Helm behaves this way
Helm has its own limit for release names (53 characters, so that suffixes still fit) but it never rewrites
the names templates produce. Whatever a chart renders is sent to the API server as is. That is why
`helm create` scaffolds `fullname` with `trunc 63 | trimSuffix "-"`, and why charts that skip it work in
staging (short release names) and fail in production (long ones). Every Kubernetes kind has its own
limit: Services and many labels 63, Deployments and ConfigMaps 253, pod hostnames 63 with truncation.

## The fix
Cap the helper: `printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-"`, apply the same
to `fullnameOverride`, and re-run the deploy. Setting `fullnameOverride` through values is an equally valid
operational workaround.

## In real life
Naming conventions like `<customer>-<service>-<env>-<region>` produce long release names exactly where the
rules are strictest. Add a CI test that renders each chart with a 50-character release name and fails if any
Service name exceeds 63 characters. Truncation can create collisions: keep the discriminating part of the name
(environment, region) at the front or use a short hash.

## Commands worth remembering
- `helm template <long-release-name> ./chart | grep -E '^  name:'` — inspect names
- `helm install --dry-run=server` — let the API server validate names
- `helm create` — reference fullname helper with truncation
- `helm list --failed` — find the release record a failed install left behind

## Common mistakes
- Shortening the release name to dodge the problem and breaking the naming convention.
- Truncating only the fullname but not label values built from the release name.
- Truncating without `trimSuffix "-"`, producing names that end in a dash (invalid).

## Helm 3 vs Helm 4
The names, limits and fix are identical. Helm 4's server-side apply reports the error as
`server-side apply failed for object ...`; Helm 3 prints the same Kubernetes message after `unable to build
kubernetes objects from release manifest`.
