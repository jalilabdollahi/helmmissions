# Not Every File Is A Manifest

## What broke
Someone saved operator documentation as `templates/usage-notes.yaml`. Helm renders every file in
`templates/` and then parses the output as YAML Kubernetes objects. Prose with a colon in line 6 is not valid
YAML (and even valid-YAML prose would not be a Kubernetes object), so rendering failed for the whole chart.

## Why Helm behaves this way
`templates/` has a simple contract: files whose names start with `_` are helpers, `NOTES.txt` is the post-install
message, and everything else must render to one or more manifests. Helm does not look at file extensions to guess
your intent; a `.yaml` file is a manifest. One bad template breaks the release because Helm renders the chart as a
whole before it contacts the cluster - which is also why nothing was half-installed.

## The fix
Put human-readable text where Helm expects it: `templates/NOTES.txt` (it can even use template syntax such as
`{{ .Release.Name }}` and is shown after install and upgrade) or a documentation folder outside `templates/`
(`docs/`, `README.md`). A Helm comment `{{- /* ... */ -}}` also works for notes that should stay beside templates.

## In real life
Charts accumulate stray files: scratch YAML, sample values, Markdown notes saved with the wrong extension.
`helm lint` points at the broken file immediately, and `helm template --debug` prints the rendered YAML so you can
see what Helm tried to parse. Add both to CI, and use `.helmignore` to keep non-chart files out of the package.

## Commands worth remembering
- `helm lint ./chart` - reports the file and the YAML error
- `helm template rel ./chart --debug` - shows the rendered output even when parsing fails
- `helm template rel ./chart | grep -c '^kind:'` - count the objects you expect
- `helm get notes <rel>` - re-print the NOTES.txt of an installed release

## Common mistakes
- Deleting the file without keeping the notes anywhere.
- Hunting for a bug in the Deployment because the error appears while installing it.
- Using a `.txt` file name for a real manifest: it would not be parsed as a manifest at all.

## Helm 3 vs Helm 4
Same behaviour. The exact wording of the YAML error depends on the YAML library; Helm 4 may report for example
"cannot unmarshal string into Go value of type util.SimpleHead" for a one-line prose file and
"error converting YAML to JSON" for prose that looks like partial YAML.
