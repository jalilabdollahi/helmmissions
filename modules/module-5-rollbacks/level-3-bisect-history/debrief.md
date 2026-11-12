# Find The Last Good Revision

## What broke
Six revisions in a week, each broken in a different way: an unpullable image tag, an nginx directive that
makes the container crash, a readiness probe pointing at a 404, and a zeroed rate table. The release
status says `deployed` for the last one and `superseded` for the rest - Helm tracks *what was applied*,
never *whether it worked*.

## Why Helm behaves this way
Every revision is a self-contained record (chart, values, rendered manifest) stored in a release Secret.
That makes old revisions inspectable with `helm get values|manifest|notes --revision N` and restorable
with `helm rollback`. A rollback re-applies revision N's manifest and values as a new revision, so you can
rollback as often as you like while you bisect - every attempt is just another history entry. What Helm
does not store is health: only `--wait`, tests and your own monitoring tell you if a revision was good.

## The fix
Treat history like a bisect: list the revisions, read the inputs of each, and test the candidates. The
newest revision that has all required behaviour (insurance on, rate correct, pods Ready) is the target:
`helm rollback freight-quote 4 --wait`.

## In real life
After an incident people often "roll back one" and discover the previous release was also broken - Friday's
hot deploy rarely was the first bad one. Annotate your pipeline: `--description` on Helm 4 (or release
notes in CI) and always deploy with `--wait` so a failed rollout shows up as a failed revision instead of
a silent `deployed`. Keep `--history-max` high enough to cover your bisect window.

## Commands worth remembering
- `helm history <rel> --max 20 -o json | jq` - machine-readable history
- `helm get values <rel> --revision N` and `helm get manifest <rel> --revision N`
- `diff <(helm get manifest r --revision 4) <(helm get manifest r --revision 6)`
- `helm rollback <rel> N --wait --timeout 2m`

## Common mistakes
- Rolling back to "the previous revision" without checking it was healthy.
- Rolling back to the first revision because it is "known to work" and silently losing a feature.
- Rolling back without `--wait` and not noticing the rolled-back revision never became Ready.

## Helm 3 vs Helm 4
Same behaviour. Remember that a plain `helm upgrade` without `--reset-values` may carry over previous user
values, so a revision's recorded values can contain more than the command line of that deploy showed.
