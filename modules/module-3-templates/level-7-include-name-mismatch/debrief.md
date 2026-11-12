# no template named "shop.labels"

## What broke
`service.yaml` called `{{ include "shop.labels" . }}`, but after the chart was renamed to `storefront` the helper in
`_helpers.tpl` was renamed to `storefront.labels`. Nothing defined `shop.labels` any more, so `include` failed
with `no template "shop.labels" associated with template "gotpl"`.

## Why Helm behaves this way
`{{ define "name" }}` registers a *named template* in one global namespace shared by every file of the chart and its
subcharts - the file name `_helpers.tpl` (the leading underscore only means "do not render this as a manifest") has
no role in the lookup. `include` and `template` search that registry by the literal string, and unlike a missing
`.Values` key, a missing template is a hard error. The convention `<chartname>.<helper>` exists to prevent name
collisions between charts; the price is that renaming a chart means renaming every reference.

## The fix
Point the include at the helper that exists. Adding an alias (`define "shop.labels"` that includes the new helper)
also works, but leaves a second name to maintain - appropriate only while other charts that depend on the old name
are migrated.

## In real life
Renames happen when a chart is forked, promoted from an example, or split from a monorepo. `helm create` generates
helpers prefixed with the *chart name*, so a copy-paste of an old chart's templates brings the old prefix along.
Parent charts that call a subchart's helper by name break the same way when the subchart is renamed.

## Commands worth remembering
- `grep -rn 'define "' templates/` and `grep -rn 'include "' templates/` - compare the two lists
- `helm template ./chart -s templates/service.yaml` - render only the failing template
- `helm lint ./chart` - finds the missing template on every file

## Common mistakes
- Deleting the labels from the Service: the install succeeds but selectors, dashboards and cost reports that
  rely on the standard labels silently stop matching.
- Renaming the *define* back to the old name: now the other templates (which use the new name) break.
- Expecting the helper's file name (`_helpers.tpl`) to matter - only the string in `define` does.

## Helm 3 vs Helm 4
No difference; both report `no template ... associated with template "gotpl"`. Helm 4 wraps it with the template
file and position, which makes the failing `include` easier to find.
