# Blocked By A Hook

## What broke
`ledger-api` ships a database migration as a `pre-install,pre-upgrade` hook Job. The script inside the Job reads
`LEDGER_DB_DSN`, but the template passed the connection string as `DATABASE_URL`. The script saw an empty value, exited
with code 64, the Job hit its `backoffLimit: 0` and Helm marked the whole install as failed. Because pre-install hooks run
before any normal resource is created, the Deployment and Service were never even submitted.

## Why Helm behaves this way
Hooks are part of the release lifecycle, not of the manifest. For an install Helm renders everything, runs the
`pre-install` hooks in weight order, and waits for each one to finish: a Job counts as done when it completes and as failed
when it fails or runs out of time. A failed hook aborts the operation and the release is recorded as `failed`. The hook's
Job and Pod are left behind (the `before-hook-creation` policy only deletes them at the *next* run), which is why
`kubectl logs` still works afterwards. That is also why a hook failure is rarely about Helm: the error is in the hook's own logs.

## The fix
Make the variable name agree between the template and the script (either side may change), then deploy again. The failed
first install is still a release, so `helm upgrade` works as long as the hook is also a `pre-upgrade` hook; otherwise
uninstall and install again. Do not skip the hook: the API expects the schema to exist.

## In real life
A migration hook is the classic place where "works on my laptop" environment variables go missing: a secret name changes,
a values key is renamed, a ConfigMap is not mounted. Pipelines should print the hook's logs on failure
(`kubectl logs job/<release>-migrate`), keep hook Jobs short with `backoffLimit` and `activeDeadlineSeconds`, and make the
script fail loudly on missing configuration instead of guessing defaults.

## Commands worth remembering
- `helm get hooks <release>` — the hook manifests stored with the release
- `kubectl logs job/<name>` — what the hook said before it failed
- `helm install --no-hooks` / `helm upgrade --no-hooks` — skip hooks (and the work they do)
- `helm template ... --debug` — see the hook Job as it will be created

## Common mistakes
- Using `--no-hooks` to get a green install: the migration is silently skipped and the app starts against an old schema.
- Creating a replacement Job with `kubectl` and calling it done: the release itself is still `failed`.
- Debugging the Deployment, which does not exist yet because the hook failed first.

## Helm 3 vs Helm 4
Both versions run pre-install hooks first and fail the release when one fails. Helm 4 reports the failure as
`failed pre-install: resource Job/<ns>/<name> not ready. status: Failed`; the wording differs between versions but the
Job and its pod are kept in both so you can read the logs.
