# Three Tiers Down

## What broke
Three independent faults, one in each tier, hid behind a single symptom ("the front end errors"). The database release
never became healthy because its `pre-install` hook Job asked for a schema migration the release does not ship, so
Helm marked the first install `failed` and created none of the database objects. The API pod was stuck in an init
container that waits for a database host name (`ledger-db-primary`) that no Service has. The front end was healthy
but called the API on port 80 while the API Service listens on 8080.

## Why Helm behaves this way
Hooks are part of the release lifecycle: a failing `pre-install` hook aborts the install before the main resources are
created, and the record stays as `failed`. Hooks are not owned by the release afterwards, so the Job (and its logs)
remains for you to read until the next run with `before-hook-creation`. Helm itself knows nothing about service
dependencies - it applied api and web without waiting for the database - so correctness of cross-release wiring
(host names, ports) is entirely in your values.

## The fix
Work in dependency order. Correct `migrations.target` (a version the chart ships) and upgrade the failed release (or
uninstall and install it again); only then do the API's init container and the front end have something to talk to.
Fix `db.host` and `api.upstream` in the values files, upgrade both releases, and confirm with the end-to-end health page.

## In real life
Pipelines that deploy tiers independently, without `--wait` or without checking exit codes, produce exactly this:
a green-looking run with three half-broken releases. On call, read bottom-up: dependencies first, then consumers.
Each fix removes noise from the next layer's symptoms, so one broken layer can mask the next fault.

## Commands worth remembering
- `helm list --failed --deployed -n NS`, `helm status REL`, `helm history REL`
- `kubectl get pods,jobs,svc,endpointslices -n NS`
- `kubectl logs job/<release>-migrate`, `kubectl logs POD -c INIT_CONTAINER`
- `helm upgrade --install REL ./chart --wait --timeout 90s`
- `helm get manifest REL | grep -A3 env:` to see what a release really runs

## Common mistakes
- Patching Deployments with `kubectl set env`: the live objects work for a minute, but the chart and the release record stay wrong.
- Skipping the failing hook with `--no-hooks`: the schema migration is the point of the hook.
- Fixing the visible tier (web) first and wasting time, because the cause is two tiers away.

## Postmortem
Root causes: an unvalidated migration target in db values; a host name copied from a different environment's naming;
a port left over from an older Service definition. Contributing factors: the pipeline treated each release as
independent and nobody read the pipeline result; no end-to-end smoke test after deploy.
Prevention: deploy in dependency order with `--wait` and `set -e`, add a smoke test of the whole path as the last
pipeline step, lint values against a schema (`values.schema.json`), and keep hook logs in the incident ticket.

## Helm 3 vs Helm 4
Behaviour is the same. A failed first `helm install` leaves a `failed` release that `helm upgrade --install` can
repair on both versions; `--atomic` (Helm 3) is called `--rollback-on-failure` in Helm 4 but would not have helped
here, since there is no earlier revision to roll back to.
