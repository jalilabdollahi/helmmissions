# DRY With A Library

## What broke
Two charts each carried a private copy of the label helper. Copies of "the same" template never stay the
same: one chart lost `part-of`, the other changed its value and its `managed-by` spelling. Nothing failed,
Kubernetes accepts any labels, but everything that depends on a convention (dashboards, cost reports,
network policies, `kubectl get -l part-of=ledger`) quietly stopped matching half of the platform.

## Why Helm behaves this way
A library chart (`type: library`) is a chart that exports named templates and nothing else. It cannot be
installed (`helm install` says "library charts are not installable") and renders no manifests of its own.
When another chart lists it under `dependencies:`, Helm loads its templates into the same template set, so
`include "platformlib.labels" .` works inside the consumer. Because `.` is the consumer's context,
`.Chart` and `.Release` inside the library refer to the consuming chart and release — that is what lets one
definition produce `name: ledger-api` in one chart and `name: ledger-worker` in the other. Only files whose
name starts with an underscore are treated as partials in a library, which is why the helpers live in
`_labels.tpl`.

## The fix
Create `platformlib` with `type: library`, move the single definition of the labels there, declare it as a
`file://` dependency of both charts, run `helm dependency update` so a packaged copy lands in `charts/`, delete
the per-chart helpers, and upgrade both releases. Keep selector labels unchanged — a Deployment selector is
immutable, so a "cleanup" that renames selector keys turns into a failed upgrade.

## In real life
Platform teams publish one library (`common`, `mycompany-lib`) to an OCI registry and version it with SemVer;
application charts depend on `~1.4.0` and pick up fixes through Renovate/Dependabot pull requests. Bitnami's
`common` chart is the best-known example. The trade-off is coupling: a bad release of the library breaks every
consumer at the next `dependency update`, so libraries need their own tests (`helm template` golden files) and
careful minor/major discipline. In CI, run `helm dependency build` (not `update`) to stay on the locked version.

## Commands worth remembering
- `helm dependency update ./chart` — resolve `Chart.yaml` dependencies, write `Chart.lock`, fill `charts/`
- `helm template ./chart | grep -A8 labels:` — see what the library produced
- `helm show chart ./platformlib` — confirm `type: library`
- `helm lint ./chart` — catches missing dependencies

## Common mistakes
- Copy-pasting the "fixed" helper into both charts. It looks identical today and drifts again next quarter.
- Forgetting `helm dependency update` after changing the library: the consumer keeps rendering the old
  packaged copy in `charts/`.
- Putting helpers in a file without the `_` prefix inside the library; Helm ignores it and the include fails.

## Helm 3 vs Helm 4
Library charts, `file://` dependencies and `include` behave identically in Helm 3.14+ and Helm 4. Helm 4
applies new releases server-side by default, which does not change anything here.
