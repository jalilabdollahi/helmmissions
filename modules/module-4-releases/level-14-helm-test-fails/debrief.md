# Red Test Suite

## What broke
The chart's test pod (`templates/tests/test-connection.yaml`) called `http://rating-service-api:8080/health`. No
Service with that name or port exists: the real Service is named after the release and listens on port 80, so the
curl pod could not resolve the host and `helm test` reported `pod rating-service-test-connection failed`.

## Why Helm behaves this way
A test is a Pod carrying the annotation `helm.sh/hook: test`. It is not created at install time; Helm stores the
rendered hook manifest as part of the release revision and `helm test <release>` creates those pods on demand and
waits for them to finish. Success means the pod ended in `Succeeded`. Because the definition comes from the stored
revision, fixing the template on disk changes nothing until you `helm upgrade` (which writes a new revision with
the new hook). The result of the last run is recorded in the release (`helm status` shows the test suite phase).

## The fix
Correct the host and port in the test (derive them from `.Release.Name` and `.Values.service.port`), upgrade, then run
`helm test` again. Deleting the test would make the failure disappear and the safety net with it.

## In real life
`helm test` is the cheapest post-deploy smoke test: run it in the pipeline after `helm upgrade --wait` and
fail the job if it is red. Tests rot when they hard-code names that the chart helpers generate; render them
from the same helpers as the Service. Use `hook-delete-policy: before-hook-creation` so leftover pods from earlier
runs do not collide, and `--logs` to print the pod's output.

## Commands worth remembering
- `helm test <rel> --logs` — run the tests and print their logs
- `helm get hooks <rel>` — the hook manifests stored in the release
- `kubectl get pods -l app.kubernetes.io/name=<chart>` — test pods stay around for inspection
- `helm status <rel>` — includes the last test suite run

## Common mistakes
- Editing the test file and re-running `helm test` without upgrading.
- Hard-coding service names or ports instead of using `.Release.Name` and values.
- Making the test always succeed (`exit 0`) to turn the pipeline green.

## Helm 3 vs Helm 4
`helm test` works the same on both, and `helm status <rel>` prints the last test suite run (phase and timestamps) on Helm 4 as on Helm 3. Helm 4's `helm status -o json` no longer includes the chart name, so use `helm history` for that.
