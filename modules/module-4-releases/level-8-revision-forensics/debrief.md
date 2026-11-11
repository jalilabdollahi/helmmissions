# Bring Back Revision 2's Setting

## What broke
Revision 3 of `product-search` set `features.search=false`, almost certainly by accident (a `--set` meant for
another environment). Revisions 4 and 5 were then layered on top by other people and carry changes that
are wanted. Search has been off ever since, and every revision claims `Upgrade complete`.

## Why Helm behaves this way
Each revision stores the chart as it was, the user-supplied values (`helm get values --revision N`)
and the rendered manifest (`helm get manifest --revision N`). That makes history a source of truth you can
diff, even when the original CI logs are gone. History is also linear: `helm rollback N` does not "go
back", it creates a new revision that copies revision N, so everything done in N+1..current is discarded
from the live release. To undo one change while keeping the rest, build a new revision from the *current*
values and change only the faulty one.

## The fix
Diff the values of revisions 2-5, find the single bad value, then `helm upgrade ... --reuse-values --set
features.search=true`. Alternatively export `helm get values` to a file, edit it and use `-f`.

## In real life
"Quick `--set` tweaks" are how production drifts away from what Git says. Teams that deploy with values files
from Git never have this problem; teams that rely on `--reuse-values` must know that the release's
stored values are the only record. Print `helm get values` into the pipeline log and keep an audit trail.

## Commands worth remembering
- `helm get values <rel> --revision N [-o yaml]` — user values of a given revision
- `helm get manifest <rel> --revision N` — rendered objects of that revision
- `helm diff revision <rel> N M` — (plugin) diff two revisions
- `helm upgrade --reuse-values` / `--reset-then-reuse-values` — how old values carry forward

## Common mistakes
- Running `helm upgrade -f only-one-change.yaml` without `--reuse-values`: every other `--set` ever used is silently reset.
- Rolling back to the "good" revision and losing later wanted changes.
- Using `--reuse-values` after a chart upgrade that added new default values: they are not picked up.

## Helm 3 vs Helm 4
`helm get values --revision`, `get manifest --revision` and `--reuse-values` work the same on both.
`--reset-then-reuse-values` (merge new chart defaults with old user values) exists from Helm 3.14 and on 4.
