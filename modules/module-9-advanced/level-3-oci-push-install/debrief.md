# Ship Via OCI

## What broke
The release job ran `helm push chart.tgz oci://registry/path/charts/payments-gateway`. Helm pushed happily —
but to `path/charts/payments-gateway/payments-gateway:0.3.0`, because `helm push` always appends the chart name
(read from the package) to the location you pass. The consumers asked for `path/charts/payments-gateway:0.3.0`,
which never existed, so the rollout failed with `FetchReference ... not found` even though the push "succeeded".

## Why Helm behaves this way
An OCI registry has no notion of "a chart repository". Each chart is one OCI repository whose name is
`<path>/<chart name>` and whose tags are chart versions. `helm push` takes a *destination namespace* and derives the
repository name and tag from the package's Chart.yaml (`name` and `version`, with `+` turned into `_`). `helm install`,
`helm upgrade`, `helm pull` and `helm show` instead take the *full* reference `oci://host/path/name` plus `--version`.
That asymmetry (push: parent path; pull/install: full path) is the single most common OCI mistake. Registries that
speak plain HTTP also need `--plain-http` on every call, including `helm push`.

## The fix
Push to the parent path and keep the full reference for consumers. Verify with `helm show chart OCI_REF --version X
--plain-http` (or `helm pull`) before touching the cluster, and compare tag lists with the registry API
(`/v2/<name>/tags/list`).

## In real life
Platform teams replace classic chart repositories (index.yaml) with OCI registries (Harbor, ECR, GHCR, ACR): CI runs
`helm package` then `helm push` on a tag, GitOps controllers (Flux `HelmRepository type: oci`, Argo CD) pull
`oci://` references with a version constraint. Tags are immutable by convention but registries often allow overwriting;
enable tag immutability for chart repositories, and promote by digest where possible. Pipelines should smoke-test
the published artifact (`helm pull`, `helm template`) in the same job that pushed it, so a wrong path fails the
release, not the deploy.

## Commands worth remembering
- `helm package ./chart -d dist` — build the .tgz named from Chart.yaml
- `helm push dist/x-1.0.0.tgz oci://host/path` — publish (parent path only)
- `helm show chart oci://host/path/x --version 1.0.0` — inspect without installing
- `helm upgrade --install rel oci://host/path/x --version 1.0.0` — deploy from the registry
- `curl localhost:5001/v2/_catalog` — list repositories in a plain registry

## Common mistakes
- Putting the chart name at the end of the push reference: the artifact lands in a doubled path.
- "Fixing" the consumer to the doubled path: it works once and diverges from everyone else's convention.
- Forgetting `--version`: OCI has no index, so Helm resolves the tag `latest` or the highest semver tag it can list.

## Helm 3 vs Helm 4
OCI support is GA in Helm 3.8+ and the push/pull semantics are identical in Helm 4. In both, a registry without TLS
requires `--plain-http` (Helm 3.13+ and Helm 4) or an `insecure` registry config; the failure without it reads
`http: server gave HTTP response to HTTPS client`.
