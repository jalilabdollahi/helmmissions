# OCI Reference Format

## What broke
The dependency was declared with `repository: oci://localhost:5001/m6-oci-dependency-url/charts/seat-cache` and `name: seat-cache`.
For OCI dependencies Helm does not treat `repository` as the full address of the chart: it appends the dependency `name`
and the version tag itself and pulls `<repository>/<name>:<version>`. With the chart name already in the repository,
Helm requested `.../charts/seat-cache/seat-cache:2.0.1`, which does not exist, and the registry answered `not found`.

## Why Helm behaves this way
Classic repositories have an `index.yaml` that lists chart names and versions; `repository` is the base URL of that index.
OCI registries have no index. A chart is simply a repository path holding tags, so Helm maps the same three fields
(`repository`, `name`, `version`) onto one reference: `oci://host/path` + `/` + `name` + `:` + `version`.
That is also why constraint ranges work differently: Helm lists the tags of `<repository>/<name>` and picks the best match.
Registries that are not TLS-protected need `--plain-http` on every Helm command that talks to them (`dependency update`,
`dependency build`, `pull`, `push`, `show`), which is separate from the `helm registry login` credentials.

## The fix
Make `repository` the parent path (`oci://localhost:5001/m6-oci-dependency-url/charts`), re-run `helm dependency update --plain-http`
so that the lock records the corrected repository, and install.

## In real life
This is the first error most teams meet when moving dependencies from a chart repo to OCI (ECR, GHCR, Harbor, ACR). The
confusing part is `helm push chart.tgz oci://registry/path` also appends the chart name: what you push to is the same parent path you
later declare as `repository:`. When a pull fails, `helm show chart oci://<repository>/<name> --version X` isolates the
problem from the parent chart. Private registries additionally need `helm registry login`, and CI needs it before `dependency build`.

## Commands worth remembering
- `helm show chart oci://host/path/name --version X [--plain-http]` — does that exact reference exist?
- `helm pull oci://host/path/name --version X --plain-http` — fetch one chart
- `helm dependency update ./chart --plain-http` — resolve and download dependencies from a plain-HTTP registry
- `helm registry login host` — authenticate to a private registry

## Common mistakes
- Putting the chart name into both `repository:` and `name:`.
- Forgetting `--plain-http` and chasing an unrelated "server gave HTTP response to HTTPS client" error.
- Pulling the tarball manually into `charts/` and leaving the declaration wrong: it installs, but nobody else can build the chart.

## Helm 3 vs Helm 4
`--plain-http` on `helm dependency update/build` exists in recent Helm 3 releases (3.13 and later) and in Helm 4. The
reference format is identical. Helm 4 reports the failing reference as a `FetchReference` error from its OCI client.
