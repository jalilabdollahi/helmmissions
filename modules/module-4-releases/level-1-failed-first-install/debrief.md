# Born Failed

## What broke
The first `helm install invoice-api` rendered fine but the Kubernetes API server rejected the Service
(`spec.type: Unsupported value: "ClusterIp"`). Helm had already written revision 1 of the release as a
Secret in the namespace, so the release now exists with status `failed`. The pipeline went red, but the
release record stayed behind.

## Why Helm behaves this way
Helm stores every revision of a release as a Secret (`sh.helm.release.v1.<name>.v<N>`) in the release
namespace. The record is written *before* the manifests are sent to the cluster, with status
`pending-install`, and then flipped to `deployed` or `failed` depending on the outcome. The description
field keeps the error text, which is why `helm history` is the first place to look. Because a record
exists, `helm install` of the same name is refused ("cannot reuse a name that is still in use"), while
`helm upgrade` is allowed: a release whose only revision failed can be upgraded, and revision 1 becomes
`superseded`.

## The fix
Correct the value (`ClusterIP`), then `helm upgrade invoice-api ./invoice-api -n helmissions --wait`.
Uninstall followed by install is equally valid for a first revision that never worked.

## In real life
CI pipelines usually run `helm upgrade --install`, which turns a failed first install into a failed
revision rather than a missing release. Teams then see a release stuck in `failed` in dashboards and
`helm list --failed`. Typos that only the API server can catch (enum casing, ports out of range, invalid
quantities) are common; `helm lint` and `helm template` do not catch them, but `helm install --dry-run=server`
does.

## Commands worth remembering
- `helm history <rel> -n <ns>` — revisions, status and the error in DESCRIPTION
- `helm list --failed -n <ns>` — show only failed releases
- `helm upgrade --install <rel> <chart>` — idempotent deploy
- `helm install --dry-run=server` — validate against the real API without creating anything

## Common mistakes
- Piping `helm template` into `kubectl apply` to "get it running": the pods start but the release stays
  `failed`, and the next pipeline run still breaks.
- Retrying `helm install` with the same name and hoping for a different result.
- Deleting only the Kubernetes objects but not the release record.

## Helm 3 vs Helm 4
Helm 4 applies manifests with server-side apply by default, so the error text begins with
`server-side apply failed for object ...`; Helm 3 reports `unable to build kubernetes objects` or the
raw API error. In both, the failed revision stays in history. Upgrading a release whose only revision
failed works on Helm 4; some older Helm 3 versions answered `has no deployed releases` and required an
uninstall first.
