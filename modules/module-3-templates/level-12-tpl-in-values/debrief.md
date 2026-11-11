# Literal Braces

## What broke
`values.yaml` contained the string `"{{ .Release.Name }}-db"` and the template copied it verbatim into the container's
environment. The pod therefore tried to resolve a host literally named `{{ .Release.Name }}-db`, which does not exist,
so its readiness check (and the application) failed.

## Why Helm behaves this way
Rendering has one pass over the chart's `templates/` files. Values are inputs to that pass, not part of it: a string
in a values file is just a string, even if it contains braces. Helm provides `tpl` for the "render this string as a
template" case. `tpl <string> <context>` parses the string with the same function set and evaluates it against the
context you pass - normally `.` (root) so `.Release`, `.Values`, `.Chart` are all available; inside `range` or `with`
pass `$`.

## The fix
`{{ tpl .Values.database.host . | quote }}`. The value keeps its dynamic part, each release resolves its own database
Service, and nothing else changes.

## In real life
`tpl` is how community charts allow `extraEnv`, `ingress.hosts`, `annotations` and whole config files in values to
refer to `{{ .Release.Name }}` or `{{ .Values.global.domain }}`. Use it deliberately: values that go through `tpl`
should be documented as templates, because a stray `{{` in a password or a regex then changes meaning or errors out.
Putting the literal host in values for one environment "works" but breaks every other release name, preview
environment and `helm template` run in CI.

## Commands worth remembering
- `helm get values <rel> --all` - what the chart received
- `helm template <other-name> ./chart | grep DB_HOST` - prove the value follows the release name
- `kubectl logs deploy/<name>` - the application usually tells you what it tried to connect to

## Common mistakes
- Passing the wrong context to `tpl` (`tpl .Values.x .Values`) - then `.Release` is missing inside the string.
- Hard-coding the final value for the current release or forcing it with `--set` on the command line.
- Applying `tpl` to values that contain secrets or user input with `{{` characters.

## Helm 3 vs Helm 4
`tpl` behaves the same. Note that Helm 4's `helm status -o json` omits the chart name; use `helm history`.
