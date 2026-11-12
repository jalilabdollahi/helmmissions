# One Setting For All Subcharts

## What broke
`region: eu-west-1` was written at the top level of the parent's `values.yaml`. The gateway template and both
subcharts read `.Values.global.region`, which was never set, so each fell back to "unset". The upgrade succeeded
and nothing in Helm output hinted at a problem.

## Why Helm behaves this way
A subchart sees its own values: its defaults merged with the parent's block named after it (`collector:`). The parent's
other top-level keys are invisible to it. There is one deliberate exception: the reserved `global:` key. Whatever is
under `global` in the parent is copied into every subchart (and sub-subchart) as `.Values.global`, so a single setting
such as region, image registry or environment reaches every component. Globals flow only downward: a subchart cannot
set a global for its siblings, and a value placed under `collector.global` is overridden by the parent's own global.
The parent's own templates read it the same way, as `.Values.global.region`, and the subchart authors agreed to
that convention.

## The fix
Move `region` under `global:` and upgrade. `helm get values telemetry --all` now shows `global.region`, and `helm template`
renders the same value into every Deployment.

## In real life
Umbrella charts rely on globals for image registry mirrors, cluster name, tenant id and storage class.
Typical failures: the value placed one level too high (this level), set under a subchart name where it is not read, or a
subchart author using `.Values.region` instead of `.Values.global.region`, in which case the parent has to set
`collector.region` explicitly. When a platform team documents "use global.X", anything else is a silent default.
Make subcharts fail loudly (`required "global.region is required" .Values.global.region`) to turn silent defaults into errors.

## Commands worth remembering
- `helm get values <rel> --all` — shows the merged `global` map and per-subchart blocks
- `helm template <rel> ./chart --set global.region=x | grep -n REGION` — try a value without upgrading
- `grep -rn "Values.global" <chart>/` — find which keys components expect
- `helm show values ./chart/charts/<sub>.tgz` — see whether a subchart documents a global

## Common mistakes
- Scoping `--set collector.region=...` for each subchart: they read `global.region`, so nothing changes.
- Hand-editing the vendored subchart templates to read a different key, which breaks on the next `helm dependency update`.
- Patching live Deployments with `kubectl set env`; the release still holds the old values.

## Helm 3 vs Helm 4
No difference: `global` is handled identically.
