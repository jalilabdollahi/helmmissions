# Range Over A String

## What broke
`allowedOrigins` was a string (`"https://shop.example"`) while the template iterates with `range`.
Go templates can range over slices, maps, integers and channels - not strings - so Helm stops with
`range can't iterate over https://shop.example` before it talks to the cluster.

## Why Helm behaves this way
Helm does not know what shape a value should have. A single origin feels like "a list with one entry",
but YAML writes a list as `- item` or `[item]`; a bare scalar stays a scalar. The template is the
contract: it says the value is a list, and Helm enforces that at render time with a Go error.

## The fix
Write the value as a list (`- https://shop.example`) and install. The same applies on the command line:
`--set 'allowedOrigins={https://a.example,https://b.example}'` builds a list, plain `--set allowedOrigins=a`
builds a string. If a chart must accept both shapes, normalise inside the template with
`{{ $origins := ternary .Values.allowedOrigins (list .Values.allowedOrigins) (kindIs "slice" .Values.allowedOrigins) }}`
- but a schema is usually the better tool.

## In real life
Lists-of-one are the most common offender: people who start with one hostname write a string, then the
chart grows a loop. Ingress hosts, CORS origins, DNS names, imagePullSecrets and tolerations all hit this.
A `values.schema.json` that declares `"type": "array"` turns the render-time stack trace into a clear
validation message and works for every environment's values file.

## Commands worth remembering
- `helm template ./chart` - fastest way to see render errors
- `helm show values ./chart` - check the intended shape of each value
- `helm lint ./chart --strict` - extra checks before release

## Common mistakes
- Changing the template to print the string: breaks the moment a second origin is added.
- Quoting a list in YAML (`"[a, b]"` is a string, `[a, b]` is a list).
- Assuming `--set a=x,y` creates a list: commas are separators between key/value pairs.

## Helm 3 vs Helm 4
Identical error and behaviour on both.
