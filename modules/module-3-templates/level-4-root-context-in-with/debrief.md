# Lost In with

## What broke
Inside `{{- with .Values.podLabels }}` the template used `{{ .Release.Name }}`. A `with` block changes what the
dot means: within it, `.` is the value you passed to `with` (here the `podLabels` map), not the chart's root
context. The map has no `Release` key, so evaluating `.Release.Name` hit a nil.

## Why Helm behaves this way
Helm templates are Go templates, and `.` is simply "the current data". At the top of a template it is the root
object (`.Values`, `.Release`, `.Chart`, `.Capabilities`, `.Files`, `.Template`). `with`, `range` and `include`
with a different argument all rebind it. Go gives you one escape hatch: `$` is set to the starting value at the
beginning of template execution and keeps pointing at the root, so `$.Release.Name` works at any depth.
(In Go's own `text/template` the message is `can't evaluate field Release in type ...`; with Helm's map-based
values you typically see `nil pointer evaluating interface {}.Name`, as here.)

## The fix
Use `$.Release.Name` inside the block. An equivalent style is to capture a variable before entering the block
(`{{- $rel := .Release.Name }}`), which also reads well when many values are needed.

## In real life
This bug appears the moment somebody wraps an old template in `with` or `range` to make a block optional.
`helm template` against default values reproduces it, but only if the guarded value is set: with an *empty*
`podLabels` the `with` body is skipped and nothing fails - so a chart can pass CI with default values and break in
the environment that actually sets labels. Test charts with every values file that is used in production.

## Commands worth remembering
- `helm template <rel> ./chart -f prod-values.yaml` - render with the values that will really be used
- `helm template ./chart --debug` - show the partial output on failure
- `{{ printf "%T" . }}` or `{{ . | toYaml }}` inside a block - what is the dot right now?

## Common mistakes
- Hard-coding the release name: the chart then breaks for every other release name.
- Moving the line out of the block: it works but changes which pods get the label when the value is empty.
- Forgetting that `range` rebinds the dot too, not only `with`.

## Helm 3 vs Helm 4
Same template semantics. The wording of the nil-pointer error comes from Go's template package and Helm's use of
generic maps, not from the Helm version.
