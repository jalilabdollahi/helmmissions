# The Password Changes Every Deploy

## What broke
The Secret template called `randAlphaNum` directly. Helm renders every template on every `install` and `upgrade`, so every
upgrade computed a brand-new random password, replaced the Secret, and (through the checksum annotation) restarted the
pods. Anything that had stored the old password - billing, a backup job, a developer's connection string - was locked out.

## Why Helm behaves this way
Templates are pure functions of values and release data; Helm stores no memory of "values it generated last time". The
only state a template can consult is the cluster itself, via `lookup`. `lookup "v1" "Secret" namespace name` returns the live
object as a map (or an empty map when it does not exist). Two caveats: `lookup` returns nothing under `helm template` and
`--dry-run=client`, because there is no API connection, and on `helm install` the first time, because the object does not
exist yet - so the template must work with an empty result. Also note that on Helm 4 the Secret is applied with
server-side apply, so the reused value is simply re-sent unchanged.

## The fix
Look up the existing Secret; if it exists, decode its password and reuse it, otherwise generate one. The registered
password survives because the fixed chart reads it from the live Secret on the first upgrade.

## In real life
Generated credentials in charts (Bitnami's databases, admin passwords, JWT secrets) use exactly this pattern. It is also a
classic GitOps trap: Argo CD and `helm template`-based pipelines never call `lookup` against the live cluster, so the
password would be regenerated on every sync; there you use an `existingSecret`, External Secrets or Sealed Secrets instead.
Add the `helm.sh/resource-policy: keep` annotation if the secret should survive `helm uninstall`.

## Commands worth remembering
- `helm get manifest <rel> --revision N` - compare what each revision applied
- `kubectl get secret <name> -o jsonpath='{.data.password}' | base64 -d` - read the live value
- `helm upgrade --dry-run=server` - the only dry-run that can evaluate `lookup`

## Common mistakes
- Pinning the password in the chart or values: stable, but now secrets live in git and the registered one is lost.
- Re-running the unfixed upgrade "to see if it settles" - each run rotates the password again.
- Forgetting that `lookup` is empty during `helm template`, so local renders always show a different password.

## Helm 3 vs Helm 4
`lookup` works in both during real installs and upgrades. In Helm 4 use `--dry-run=server` to see lookups in a dry run
(Helm 3: `--dry-run=server` also exists on install/upgrade from 3.13+; before that dry runs were client-only).
