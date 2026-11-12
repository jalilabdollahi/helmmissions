# Silent Pipeline Failure

## What broke
The staging stage could not run because `values/staging.yaml` was never committed, so `helm upgrade --install` printed an error.
The shell script did not stop: with no `set -e`, execution continued to the next line, which read the "promoted build" back from a
staging release that does not exist and got an empty string. That empty string was passed to prod as `--set image.tag=`, producing the image
reference `busybox:`. The rollout never finished, `--wait` timed out and the prod release became `failed`, while the old pods kept
serving. The CI job itself was green, because the exit status of a shell script is the status of its last command.

## Why Helm behaves this way
Helm reports failures through its exit code and stderr; it cannot stop your script. A bash script continues after a failing
command unless `set -e` (or explicit checks) says otherwise, and `set -u`/`pipefail` catch unset variables and failures hidden in
pipelines. `--set image.tag=` is a valid way to set an empty string, so Helm happily renders `busybox:`; image names are only
validated by the kubelet. A failed upgrade does not remove the previous ReplicaSet, which is why the outage was partial.

## The fix
Provide the missing staging values from the documented environment table, make the script fail fast (`set -euo pipefail` or an explicit
exit in the deploy function), and re-run the pipeline: dev, staging, then prod receives the staged build and the failed release
upgrades to a clean revision. Test the fail-fast behaviour by forcing staging to fail.

## In real life
"Green pipeline, broken prod" is almost always an unchecked exit code or an empty variable. Promotion jobs should treat every stage as a
gate, assert that values they read are non-empty (`${VAR:?}`), print what is promoted, and run a smoke test between stages. Required
files should be verified up front, before the first environment is touched.

## Commands worth remembering
- `set -euo pipefail` at the top of every pipeline script; `${VAR:?message}` for required values
- `helm list -A --failed --deployed`, `helm history REL -n NS`, `helm get values REL -n NS`
- `kubectl describe pod POD` (Events: `InvalidImageName`)
- `bash -x pipeline.sh` to trace what ran after the error
- `helm lint` and `helm template ... -f values/ENV.yaml` for every environment in CI

## Common mistakes
- Fixing prod by hand with `helm upgrade` and leaving the pipeline unfixed: the next staging problem repeats the incident.
- Adding the missing file and not touching the script: nothing prevents the next silent failure.
- Adding `set -e` but forgetting that the real cause (the missing staging data) is still there.

## Postmortem
Root causes: a values file missing for one environment; a pipeline script without fail-fast semantics; an unchecked empty variable
promoted to prod. Contributing factors: the job reported success; no per-stage smoke test; staging was added after the pipeline was written.
Prevention: `set -euo pipefail`, required-file checks, `helm upgrade --install --atomic/--rollback-on-failure` in prod, promotion of
immutable build ids that are verified before use, and a pipeline test that simulates a failing stage (as the validator did).

## Helm 3 vs Helm 4
The exit code behaviour is identical. On failure `--atomic` (Helm 3) / `--rollback-on-failure` (Helm 4) would have restored the previous
revision automatically after the bad prod rollout, which is worth considering for production stages.
