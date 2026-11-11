# Number In An Env Var

## What broke
The template wrote `value: {{ .Values.listenPort }}`. Rendered, that is the text `value: 2525`, and YAML parses an
unquoted 2525 as an integer. The Kubernetes `EnvVar.value` field is a string, so the API server refused the
Deployment: `expected string, got ... Value:2525`.

## Why Helm behaves this way
Templates are text-in, text-out; Helm never sees a "number" or a "string" in the output, only characters. The YAML parser
that runs afterwards infers types from the characters: `2525` is an int, `true`/`yes` a bool, `1.10` a float, `~` null.
Anything that must be a string in Kubernetes (env values, annotation values, label values, ConfigMap data) needs
`quote` (or `squote`, or `toString | quote`). `helm template` and `helm lint` do not know the Kubernetes schema, so
both pass; Helm 4's server-side apply and Helm 3's strict decoding then reject the object. This is also why moving the
quotes into values.yaml cannot help: the quoting that matters is in the *output*.

## The fix
`{{ .Values.listenPort | quote }}`. Use `quote` by habit for every env value, annotation and label that comes from values.

## In real life
It tends to appear when a port, timeout, boolean flag or replica count is turned from a hard-coded string into a value.
Booleans are the nastier sibling: `value: {{ .Values.debug }}` renders `value: true` and fails the same way, while
`value: {{ .Values.version }}` with `1.10` silently becomes `1.1`.

## Commands worth remembering
- `helm template ./chart | grep -A1 <ENV_NAME>` - look at how the value is actually printed
- `kubectl explain pod.spec.containers.env.value` - confirm the type Kubernetes expects
- `helm template ./chart --dry-run=server` - surface type errors before the real install (Helm 3: `--validate`)

## Common mistakes
- Quoting the number in values.yaml: it fixes nothing, the template prints it unquoted again.
- Hard-coding the value in the template: the install passes but `listenPort` no longer drives anything.
- Re-running `helm install` after the failure and hitting `cannot reuse a name that is still in use`; use
  `helm upgrade --install`.

## Helm 3 vs Helm 4
Helm 3 reports `json: cannot unmarshal number into Go struct field EnvVar.spec.template.spec.containers.env.value of type
string`; Helm 4 reports the server-side apply form shown in this level. The cause and the fix are identical.
