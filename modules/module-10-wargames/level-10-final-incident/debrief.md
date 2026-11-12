# The Final Incident

## What broke
Four independent faults had to be repaired in the right order. (1) The CI run that deployed prod was killed in the middle of a pre-upgrade hook, leaving
revision 2 of `tideline` in `pending-upgrade`; Helm will not start a new operation on a release that looks busy. (2) The umbrella chart's dependency was
stale: `Chart.yaml` asks for `cache ~1.2.0` but `Chart.lock` and `charts/` still hold 1.1.0 (`helm dependency list` says `wrong version`), and Helm would
happily have deployed the old cache. (3) Prod's values asked the migration hook for schema 14 while the database was at 12; the hook refuses to skip a version, so
every prod upgrade would fail in `pre-upgrade`. (4) Staging's values pointed at the production database host, which the application's own health page reports as degraded.

## Why Helm behaves this way
A release revision is written as `pending-*` before the operation starts and only becomes `deployed` or `failed` when the client finishes; if the client dies, nothing
updates it, and Helm treats it as an operation in progress. A rollback creates a new revision from an old good one and, as a new operation, supersedes the pending state
(deleting the pending revision's Secret is the other way out). Dependencies are resolved by `helm dependency update/build`, never at install time: Helm only checks that something
named `cache` is present in `charts/`. Hooks run as part of the release and a failing hook fails the whole upgrade. Values are layered file by file, so a later file silently overrides an earlier one.

## The fix
Triage in layers: release state, then pipeline inputs (dependencies, values), then application behaviour. Refresh the dependency, free the stuck release with
`helm rollback` to the last good revision, correct prod's schema target and staging's database host, and run the pipeline for staging and then prod. The migration hook must
run, not be bypassed.

## In real life
Production incidents are rarely one bug. A killed runner, a half-updated lock file, a copy-paste of a prod value into staging, and an unvalidated number in an override file
can all be waiting for the one deploy that touches them. Seasoned on-call engineers go bottom-up and verify each layer before looking at the next, keep a timeline, avoid
destructive shortcuts (`uninstall`, `--no-hooks`, deleting history) under pressure, and finish by proving the pipeline works from a clean checkout.

## Commands worth remembering
- `helm list -A`, `helm history REL -n NS`, `helm rollback REL N --wait`
- `kubectl get secret -l owner=helm,name=REL -n NS`; `kubectl delete secret sh.helm.release.v1.REL.vN` (last resort for a pending revision)
- `helm dependency list|update|build ./chart` (`--plain-http` for an HTTP-only OCI registry)
- `kubectl logs job/HOOK`, `kubectl describe job HOOK`
- `helm get values REL --all`, `helm template ./chart -f values/common.yaml -f values/ENV.yaml`

## Common mistakes
- Using `--no-hooks` to get past the failing migration: the schema is then out of step with the application.
- Uninstalling prod to clear the stuck state: a production outage and lost history.
- Fixing prod and forgetting staging, or forgetting that the stale dependency silently deploys an old cache.

## Postmortem
Root causes: an interrupted CI run (no cleanup for pending releases); a lock file not refreshed after a Chart.yaml bump; an out-of-range override in prod values; a prod host copied into staging.
Contributing factors: no CI step that checks `helm dependency list`; nobody acted on QA's staging report; the pipeline runs on an unreliable runner without `--rollback-on-failure`.
Prevention: run `helm dependency build` (fails on a stale lock) in CI, add `values.schema.json` bounds for the schema target, use `helm upgrade --rollback-on-failure` (Helm 4;
`--atomic` in Helm 3) and a cleanup job for pending releases, deploy staging with a config check that rejects prod hosts, and take QA's reports seriously.

## Helm 3 vs Helm 4
A killed upgrade leaves `pending-upgrade` in both. `--atomic` is `--rollback-on-failure` in Helm 4. `helm dependency update` against the local HTTP registry needs `--plain-http`
in Helm 4 (and a recent Helm 3). Behaviour of hooks, rollback and dependency checks is otherwise the same.
