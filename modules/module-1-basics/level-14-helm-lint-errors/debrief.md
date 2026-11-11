# Lint Before You Ship

## What broke
The CI gate `helm lint --strict` reported several unrelated problems in `Chart.yaml`: an unquoted `appVersion`
(YAML parsed `2.3` as a number), a `sources` entry that is not a URL, a chart `version` that is not SemVer, and an
uppercase chart name that leaked into object names (`Newsletter`) which Kubernetes rejects. A missing icon is only
an INFO message.

## Why Helm behaves this way
`helm lint` is a static check with three severities. `[ERROR]` makes lint fail. `[WARNING]` is reported but
does not fail a plain run - with `--strict` every warning becomes a failure. `[INFO]` never fails. Lint validates the
chart metadata against the Chart.yaml rules, renders the templates with sample values, and checks the resulting
objects (valid names, deprecated or removed API versions...). It never contacts a cluster, so it is cheap and safe to
run on every commit.

## The fix
Repair each message at its source: quote `appVersion` (it is free text, so YAML types must not interfere), give
`sources` real URLs, use a MAJOR.MINOR.PATCH `version`, and keep the chart name lowercase DNS-1123 compatible.
Then rerun the gate, and install the chart. Do not "fix" lint by dropping `--strict` or deleting the checks - the gate
exists to protect the registry and the cluster.

## In real life
Typical pipeline: `helm lint --strict` -> `helm template | kubeconform` -> `helm package` -> publish. Lint
catches problems that otherwise surface only at install time or, worse, when a consumer's tool (Artifact Hub, a
Renovate bot, `helm dependency update`) chokes on your chart metadata. Pass the same values files that you deploy
with: `helm lint --strict -f values-prod.yaml ./chart`.

## Commands worth remembering
- `helm lint --strict ./chart` - warnings become failures
- `helm lint ./chart -f values-prod.yaml --set key=val` - lint with real values
- `helm template rel ./chart | kubectl apply --dry-run=client -f -` - check object validity locally
- `helm show chart ./chart` - the parsed metadata

## Common mistakes
- Dropping `--strict` instead of fixing warnings.
- Leaving the version as `1.0`: lint warns, and registries and dependency ranges treat it inconsistently.
- Believing lint verifies that every value your templates use exists: it does not (see below).

## Helm 3 vs Helm 4
`helm lint --strict` does not fail on a template that reads a missing value (e.g. `.Values.replicas` instead of
`.Values.replicaCount`) in Helm 4 - such values render as empty - so keep a values schema or a `required` check for that.
Helm 4 also does not complain if the chart directory name differs from the chart name. The severity of metadata
messages (appVersion type, SemVer, URLs) is as described above.
