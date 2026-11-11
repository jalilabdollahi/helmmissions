# Helper Needs A Dict

## What broke
The helpers `mailer.fullname` and `mailer.selectorLabels` read `.ctx.Release.Name` and `.component`, i.e. they expect a
dictionary with the root context and the component name. The two templates called them with `.`, the root context itself.
Inside the helper `.` was therefore the root map, which has no `ctx` key, so `.ctx` was nil and `.ctx.Release` failed with a
nil pointer.

## Why Helm behaves this way
A named template receives exactly **one** argument and sees it as `.`. There is no keyword or positional-parameter
system, so when a helper needs more than the root context (a component, a suffix, a flag) the convention is to pack the
arguments into a map with `dict` - and to pass the root context along as `ctx` or `$`. That is why you see
`(dict "ctx" . "component" "api")` in charts such as the Bitnami ones. The helper and its callers must agree on the shape;
Go templates cannot check it for you, and a missing map key yields nil instead of an error until you dereference it.

## The fix
Pass the dict at every call site, with the right component for each file. Two other correct designs: have the helper take
the root context and compute the component from something it can see (for example `.Template.Name`, as one of this
level's alternative solutions does), or give each component its own helper. Pick one convention per chart and document it
in a comment above the helper, as this chart does.

## In real life
Multi-component charts (api, worker, scheduler, migration job) grow helpers with a second parameter, and the usual
failure is one forgotten call site. `grep -n 'include "mailer' templates/` is the quick audit. If only some call sites are
wrong, the render fails at the first one executed - not necessarily the one you edited last.

## Commands worth remembering
- `helm template ./chart` - fails fast on the first bad call
- `grep -rn 'include "<chart>\.' templates/` - list all helper calls and compare their arguments
- `{{ printf "%#v" . }}` inside a helper - debug what the helper really received

## Common mistakes
- Fixing one call site and assuming the rest are fine.
- Copy-pasting the `api` dict into worker.yaml: the names collide and the worker is never created.
- Passing `$.Values` instead of the whole context and then missing `.Release`/`.Chart` in the helper.

## Helm 3 vs Helm 4
Same template semantics. Helm 4 prints the nested location (template file, then the helper file and line) which makes the
chain of calls easier to follow.
