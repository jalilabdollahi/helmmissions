# Lines Glued Together

## What broke
`replicas: {{ .Values.replicaCount -}}` carried a right-hand trim marker. In Go templates `{{-` removes all whitespace
before the action and `-}}` removes all whitespace after it - and whitespace includes newlines and the next line's
indentation. The output became `replicas: 2revisionHistoryLimit: 2`, which is not valid YAML.

## Why Helm behaves this way
Helm renders the template to plain text first and parses YAML afterwards. The trim markers exist so that control actions
(`if`, `range`, `define`, `end`) can sit on their own lines without leaving blank lines in the output. They are a text
tool and know nothing about YAML structure. Used on a line that *prints* a value, `-}}` glues the following line to it.
The rule of thumb: put `{{-` on actions that live on their own line (`{{- if ... }}`, `{{- end }}`), and use plain `}}`
at the end of lines that emit content. When something is glued together, `helm template --debug` shows the exact text.

## The fix
Use `}}` instead of `-}}` where the line has to end with a newline. Keep the left trim on standalone control lines.

## In real life
Over-chomping typically appears after a "cleanup" PR that removes blank lines from rendered output or after copying an
`if`/`end` block from another chart. The failure message talks about YAML, not templates, and the line number refers to the
*rendered* file, so many people stare at the wrong line. Another frequent variant is under-chomping, which leaves blank
lines or breaks `|` block scalars.

## Commands worth remembering
- `helm template ./chart --debug` - prints the manifest even when it is invalid YAML
- `helm template ./chart -s templates/deployment.yaml | cat -A | head` - show spaces, tabs and line ends
- `helm lint ./chart` - reports the YAML error per template

## Common mistakes
- Deleting the glued line: the chart installs but loses the setting.
- Adding spaces after the value: the trim marker removes them again.
- Counting lines in the template file instead of in the rendered output.

## Helm 3 vs Helm 4
No difference; the YAML error text comes from the YAML library and is the same on both.
