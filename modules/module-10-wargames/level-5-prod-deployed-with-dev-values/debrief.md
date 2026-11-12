# Dev Values In Prod

## What broke
Three small things combined into "prod runs the dev configuration". The `prod` branch of `deploy.sh` selected
`values-dev.yaml` (a copy-and-paste slip). The same script used `helm upgrade --reuse-values`, so settings written
by earlier revisions were carried forward into every later upgrade; keys that `values-prod.yaml` does not set (payments mode,
debug endpoints) therefore kept their dev values even after the file selection was corrected. Finally `values-prod.yaml`
spelled the log level key `loglevel`, which the chart does not read, so it was silently ignored.

## Why Helm behaves this way
User-supplied values are stored in the release record. `--reuse-values` reuses those instead of starting from the
chart defaults; `-f` files are merged on top, key by key. So a file that is "complete" for you is only a *patch* on
the old release. Unknown keys are not errors in Helm (no schema, no strict mode), and flags written once in a script
quietly outlive the reasons they were added. With `--reset-values` (or by default in a fresh install) the release is
computed only from chart defaults plus the files you pass.

## The fix
Select the prod values file in the prod branch, start each deploy from the files rather than from the previous release
(`--reset-values`, or drop the flag), and correct the key name. Re-run the pipeline and confirm with `helm get values`
and the application's own configuration page. Run it twice: a good pipeline gives the same result every time.

## In real life
"Wrong values to the wrong environment" is among the most expensive deploy mistakes, and almost always a pipeline script
problem rather than a chart problem: a case statement with a missing branch, a variable that defaults to dev, a `--reuse-values`
added to speed things up. Make the environment explicit (fail if it is unset), print the values being used, add a
`values.schema.json` so typos fail the render, and diff `helm get values` against the file before and after.

## Commands worth remembering
- `helm get values REL -n NS` and `helm get values REL --all`
- `helm template ./chart -f values-prod.yaml | grep -A6 env:`
- `helm upgrade --install REL ./chart --reset-values -f values-prod.yaml`
- `helm diff upgrade` (plugin) or `helm template | kubectl diff -f -` before applying

## Common mistakes
- Upgrading prod by hand once and calling it done: the next pipeline run puts the dev values back.
- Fixing the file selection and trusting the result without looking at the computed values.
- Removing the dev-only keys from the live release with kubectl instead of fixing the pipeline.

## Postmortem
Root causes: wrong values file in a script branch; `--reuse-values` in a multi-environment pipeline; an unvalidated
misspelled key. Contributing factors: no review of what a prod deploy would change; the config page was nobody's job to read.
Prevention: a values schema, an explicit environment check, a post-deploy assertion on the environment name
(`environment=prod`), and a protected prod stage that prints `helm get values` before the upgrade.

## Helm 3 vs Helm 4
Both versions honour `--reuse-values` and `--reset-values`. In Helm 4 an upgrade with no `-f`/`--set` at all reuses the
previous user values by default, and as in Helm 3 an upgrade with `-f` replaces them, unless `--reuse-values` is given.
