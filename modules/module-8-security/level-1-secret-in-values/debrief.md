# Password In Git

## What broke
The chart accepted the database password as an ordinary value, so `values.yaml` carried it in plain text and
the Deployment received it as a literal `env.value`. Nothing was failing at runtime — the problem is that the
secret now lives in git history, in `helm get values`, in every stored release revision (Helm keeps them
as Secrets in the namespace) and in `kubectl get deploy -o yaml`. Anyone with read access to any of those has
the production password.

## Why Helm behaves this way
Helm is a templating engine: whatever you pass as a value is written into the manifest and into the release
record. It has no notion of "sensitive" values. Even a rendered `kind: Secret` only base64-encodes the data,
which is encoding, not encryption, and the values that produced it are still stored with the release.
The safe pattern keeps the secret itself outside Helm's data path: the chart takes only a *reference*
(`existingSecret` + key) and the pod resolves it at runtime through `secretKeyRef`.

## The fix
Create the Secret out of band (`kubectl create secret`, an external-secrets operator, sealed-secrets, a CSI
driver), empty the password in values, set `db.existingSecret`, and `helm upgrade`. Because the old password was
exposed, rotate it: the new Secret must hold a different value, changed in the database as well.

## In real life
Secret scanners (gitleaks, GitHub push protection) find these within minutes of a push, but deleting the line
in a later commit does not help: the value stays in history, forks, CI logs (`--debug` prints values) and
the release history. Teams get bitten when a `values-prod.yaml` is "temporarily" committed, or when
`--set db.password=$PASS` in a pipeline shows up in the CI log and in `helm get values`. Treat anything that was
ever in git as leaked and rotate.

## Commands worth remembering
- `helm get values REL -n NS` / `helm get manifest REL` — see exactly what a release exposes
- `kubectl create secret generic NAME --from-literal=key=value` / `--from-file=key=path`
- `kubectl get secret NAME -o jsonpath='{.data.password}' | base64 -d`
- `helm template ... | grep -i password` — cheap CI check

## Common mistakes
- Moving the password into another values file (`values-secret.yaml`) — still plaintext in the repo.
- Passing it with `--set` — it disappears from git but stays in the release record and the CI log.
- Setting `existingSecret` before the Secret exists: the pod sits in `CreateContainerConfigError`.
- Reusing the leaked password in the new Secret: moving it is not the same as rotating it.
