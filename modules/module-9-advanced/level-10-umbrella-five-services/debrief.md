# Umbrella Down

## What broke
Two unrelated defects were hidden inside one umbrella chart. The `pricing` subchart's template dereferenced
`.Values.resources.limits.cpu` while its defaults only had `requests` — Go templates cannot read a field of a missing map, so rendering
aborted with `nil pointer evaluating interface {}.cpu` and the whole release failed. Once that was fixed, another bug stayed invisible: the
`cart` subchart built its image from its own `.Values.imageRegistry` instead of `.Values.global.imageRegistry`, so it silently ignored the
platform-wide registry that the other four honoured.

## Why Helm behaves this way
An umbrella renders every subchart in one pass, so a single template error anywhere stops the entire release — and the error path names the
subchart (`marketplace/charts/pricing/templates/...`), which is your map. Values flow down: each subchart sees its own `values.yaml`, overridden by
the parent's `<subchart>:` block, plus a shared `global:` map that the parent controls. `global` is the only built-in way to configure all
subcharts at once, but it only works if every subchart actually reads `.Values.global.*`; Helm cannot enforce it. Missing keys are not errors in
templates until you dereference *through* them, which is why `.Values.resources.limits.cpu` fails while `.Values.resources.limits` would just be empty.

## The fix
Make the data the template needs exist (defaults in the subchart, or `default`/`dig` in the template so it degrades gracefully), and align every
subchart on the same global lookup. Then test the policy, not the symptom: render with a different `global.imageRegistry` and assert that every
image changed.

## In real life
Platform teams ship umbrellas of a dozen services, each maintained by a different team, and "company-wide" settings (registry mirror, pull secrets,
labels, node selectors, tracing endpoints) must reach all of them. Common failures are one subchart that never learned the convention, values nested
one level too deep or too shallow, and template errors only triggered by a particular override. Guard against it with CI jobs that render the umbrella
with every environment's values, a `--set global.*` sweep that greps for hard-coded registries, JSON schemas for `global`, and a shared library chart for
image/label helpers so the convention lives in one place.

## Commands worth remembering
- `helm template REL ./umbrella --debug` — full error context with the failing template path
- `helm template REL ./umbrella | grep -E '^# Source|image:'` — see which subchart produced which image
- `helm template ... --set global.imageRegistry=X | grep image:` — test global values end to end
- `helm get values REL --all` — the computed values per subchart after install
- `helm show values ./umbrella/charts/NAME` — a subchart's defaults

## Common mistakes
- Fixing the visible error and stopping: the silent second bug (registry ignored) ships to production.
- Hard-coding the registry in the subchart or in `cart.imageRegistry`: it looks right until the global is switched.
- Editing only `values.yaml` of the umbrella when the template dereferences a deeper path that no layer defines.

## Helm 3 vs Helm 4
Template evaluation, `global` propagation and the nil-pointer error text are identical in Helm 3 and Helm 4. Helm 4 installs with server-side apply by
default, which only matters once rendering succeeds (it would also reject an unknown field in a rendered object).
