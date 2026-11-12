# The Competing Dependency List

## What broke
`payroll` is an `apiVersion: v2` chart, so its dependencies belong in `Chart.yaml`. A leftover Helm 2 style
`requirements.yaml` still sat next to it and listed only `tax-tables`. Helm loads both files, and the legacy file's list
replaced the one from `Chart.yaml`. `pay-calendar` was therefore never resolved, never locked, never packaged and never
deployed, and the only trace was a one-line INFO message that most pipelines do not surface.

## Why Helm behaves this way
Helm 2 and v1 charts kept dependencies in `requirements.yaml` (with `requirements.lock`). Chart API v2 merged them into
`Chart.yaml` but Helm kept reading `requirements.yaml` for backward compatibility, including for v2 charts. The
loader parses `Chart.yaml` first and then unmarshals `requirements.yaml` into the same metadata structure, so the
`dependencies` list in the later file replaces the earlier one wholesale. There is no merge and no conflict warning, which is
why the new entry in `Chart.yaml` was ignored. Everything downstream (`helm dependency list/update/build`, lint, install, package) sees
only the winning list.

## The fix
Declare dependencies in one place: delete `requirements.yaml`, run `helm dependency update` so that `Chart.lock` and `charts/` match the
full list, and upgrade. Appending to the legacy file would work today but keeps a trap armed for the next person.

## In real life
Charts that were created with Helm 2 and bumped to v2 by changing one line are everywhere. The failure appears when somebody later
edits the *new* location and nothing happens. Make `helm dependency list` part of review (does it match what the pull request
declares?), and grep for `requirements.yaml` and `requirements.lock` when migrating a chart.

## Commands worth remembering
- `helm dependency list ./chart` — the effective dependency list
- `helm show chart ./chart` — the parsed `Chart.yaml` metadata as Helm sees it after loading
- `helm dependency update ./chart` — resolve and re-lock
- `helm lint ./chart` — also warns about missing dependencies

## Common mistakes
- Adding the missing dependency to `requirements.yaml` instead of retiring the file.
- Removing the new entry from `Chart.yaml` so that both lists "agree" (the calendar is then gone for good).
- Forgetting `helm dependency update` after deleting the file: the old `Chart.lock` still lists one subchart.

## Helm 3 vs Helm 4
The curriculum's classic story says a v2 chart *ignores* `requirements.yaml`. Verified on Helm 4.3 (and the loader code is unchanged since Helm 3):
it does not ignore it. It still reads the file, logs an INFO/warning line, and lets it override `Chart.yaml`. So the real-life symptom is the reverse:
the entries in `Chart.yaml` that go missing. Helm 4 prints the notice as `level=INFO msg="Warning: Dependencies are handled in Chart.yaml since apiVersion \"v2\"..."`.
