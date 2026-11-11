# The Hotfix That Vanished

## What broke
During an incident the on-call engineer raised the connection pool with `kubectl set env`. That change
existed only in the live Deployment. The next routine `helm upgrade` rendered the chart (pool size 5 from
`values.yaml`) and the cluster was reconciled back to what Git said - the outage returned and nobody could
see why, because no Git change had touched the pool.

## Why Helm behaves this way
Helm owns the objects it creates. On every upgrade it renders the chart and patches the live objects
towards the rendered manifest; Helm records the manifest of each revision, not the edits made behind its
back. Whether a manual edit survives depends on how Helm applies the change: a three-way patch (old
manifest, new manifest, live object) or server-side apply with field ownership. In our Helm 4.3 lab a
release that was applied client-side had the live value overwritten silently, while a release applied
server-side refuses to overwrite fields owned by another manager and fails with a conflict - which is why
people end up adding `--force-conflicts` to pipelines and losing hotfixes anyway. Either way: anything not
in the chart and values is temporary.

## The fix
Move the change into the source of truth (`db.poolSize: 40` in `values-prod.yaml` or the chart default) and
deploy it through the pipeline so a new revision records it.

## In real life
"Hotfix then forget" is one of the classic causes of repeat outages. Mature teams do two things: they
treat `kubectl edit/set/patch` on Helm-managed objects as an incident-only action that must be followed by
a Git change before the incident is closed, and they run a drift check (`helm diff upgrade`, or compare
`helm get manifest` with live objects) so drift is found before the next deploy finds it.

## Commands worth remembering
- `helm get manifest <rel>` vs `kubectl get <obj> -o yaml` - what Helm thinks vs what runs
- `helm get values <rel> --all` - the values the last revision was rendered with
- `helm template ./chart -f values-prod.yaml` - preview exactly what the pipeline will apply
- `helm upgrade --install ... -f values-prod.yaml` - keep every setting in files

## Common mistakes
- Repeating the `kubectl set env` hotfix: it works until the next deploy.
- Using `--set` on the command line once: it is stored in that revision, but the next pipeline run without it
  reverts it.
- Using `helm rollback` to "get the hotfix back": a rollback restores recorded revisions, and the hotfix is in none.

## Helm 3 vs Helm 4
Helm 4 uses server-side apply for new releases and surfaces field-manager conflicts; releases created by
Helm 3 (or with `--server-side=false`) keep the client-side behaviour, where our test showed live edits being
overwritten silently. Helm 3's three-way merge can keep live-only changes when the chart does not touch the
field, so do not rely on either behaviour - keep the change in Git.
