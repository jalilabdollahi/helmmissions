# Undo An Uninstall

## What broke
`helm uninstall --keep-history` removed every Kubernetes object of `loyalty-points` but kept the release
records. The release is no longer listed by `helm list` (which hides uninstalled releases), so it looks as
if it never existed, even though Helm still has everything needed to bring it back.

## Why Helm behaves this way
Normally `helm uninstall` deletes the release Secrets and the history with it. With `--keep-history` Helm
keeps them and marks the *last* revision with the status `uninstalled`; no extra revision is created (a
subtle point: revision 2 here is both the last live configuration and the "uninstalled" record).
Because every revision contains the full chart and values, `helm rollback <rel> <N>` can re-create the
objects from any stored revision and write a new revision `Rollback to N`. Without a revision number,
rollback targets the revision before the current one, which here is the *older* configuration.

## The fix
Look at `helm history` and `helm get values --revision`, pick the revision that was live, and run
`helm rollback loyalty-points 2 -n helmissions`. The history continues with a new deployed revision.

## In real life
Some teams use `--keep-history` to enable audits and "oops" recovery; others use it on release names that
are reused for many environments. It also blocks a plain `helm install` of the same name ("cannot reuse a name
that is still in use") until the record is removed with `helm uninstall` (no flag) or overridden with
`--replace`. Data held in PVCs is not restored by Helm: PVCs are deleted with the release unless they use
`helm.sh/resource-policy: keep`.

## Commands worth remembering
- `helm list --uninstalled` — releases whose history was kept
- `helm history <rel>` / `helm get values <rel> --revision N` — decide what to restore
- `helm rollback <rel> <N> --wait` — resurrect revision N
- `helm uninstall <rel> --keep-history` — uninstall but keep records

## Common mistakes
- Running `helm rollback <rel>` without a revision and restoring the older configuration.
- Assuming a reinstall from Git is equivalent: you lose values that were only ever passed with `--set`.
- Forgetting that PVC data is gone after the uninstall.

## Helm 3 vs Helm 4
Behaviour is the same in both. In Helm 4 `helm list` has no `-a/--all` flag; use `--uninstalled`
(and `--deployed`, `--failed`, `--pending`) to select statuses.
