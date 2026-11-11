# Disabled But Still Deployed

## What broke
The dependency was declared with `condition: search.enable`, while the values (and the rest of the chart) use
`search.enabled`. Helm looked for `search.enable`, did not find it, and left the subchart switched on. Setting
`search.enabled: false` therefore had no effect on the dependency. No warning is printed.

## Why Helm behaves this way
A dependency `condition` is a comma-separated list of value paths. Helm evaluates them in order and uses the first one
that resolves to a boolean in the *merged* values: true keeps the subchart, false removes it from the render
(its templates, and its own subcharts, are never evaluated). If none of the paths exists, the condition is
ignored and the default applies, which is *enabled*. That default is what makes a typo dangerous: a misspelled
path fails open. A condition also takes precedence over `tags` for the same dependency.

## The fix
Make the path in `Chart.yaml` identical to the key in `values.yaml` (`search.enabled`), refresh the lock because
the declaration changed, and upgrade. Prove the toggle both ways with `helm template`, with and without `--set search.enabled=true`.

## In real life
Feature-flag style subcharts (search, metrics, ingress, a bundled database) are usually behind a condition.
Typos, renamed values and per-environment values files that spell the key differently produce "disabled but
still deployed" tickets, which cost real money when the subchart is a database or a GPU workload.
Review `condition:` lines like code, and keep a CI check that renders the chart with the switch on and off.
Deleting the objects with `kubectl delete` does not help: they belong to the release and come back on the next upgrade.

## Commands worth remembering
- `helm template <rel> ./chart | grep <subchart>` — does the subchart render?
- `helm template <rel> ./chart --set <path>=true` — flip the switch without editing files
- `helm show chart ./chart` — the parsed dependency list with its conditions
- `helm get manifest <rel>` — what the release actually owns

## Common mistakes
- Deleting the dependency from `Chart.yaml`: the subchart is gone, but so is the ability to turn it on.
- Hot-fixing with `kubectl delete`: the release still owns the objects and recreates them on the next upgrade.
- Expecting a typo in `condition:` to raise an error: it silently enables the subchart.

## Helm 3 vs Helm 4
Same behaviour in both: conditions whose path is missing are ignored.
