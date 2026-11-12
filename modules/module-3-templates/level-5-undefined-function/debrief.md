# function "uppercase" not defined

## What broke
The template piped a value through `uppercase`. There is no such function: Go's template language has a small set
of built-ins (`and`, `eq`, `printf`, `len`, ...) and Helm adds the Sprig library plus a few Helm-specific
functions (`include`, `tpl`, `toYaml`, `lookup`, `required`). Sprig spells the string function `upper`.

## Why Helm behaves this way
Go resolves function names at parse time, not at run time. That is why this error is a `parse error` that names the
template and line, appears for *every* command that loads the chart (`install`, `template`, `lint`), and never leaves
a release behind. It also means a typo inside a branch that is never executed still breaks the chart: the whole file
must parse, even the `if` branch that today's values would skip.

## The fix
Use `upper`. Pipelines read left to right (`.Values.environment | upper | quote`), and the same call can be written
in prefix form (`upper .Values.environment`) - both are valid.

## In real life
Developers coming from Jinja, JavaScript or Python guess function names (`uppercase`, `toUpper`, `capitalize`,
`join` vs `concat`). Keep the Sprig function reference open, and run `helm lint` / `helm template` in CI so the typo
fails in the pull request. When a function exists in Helm 3 but not in a library you assumed (for example when moving
a template between charts that target different Helm versions), the same message appears.

## Commands worth remembering
- `helm template ./chart` - fastest way to find parse errors
- `helm lint ./chart` - reports parse errors per template
- Sprig docs (masterminds.github.io/sprig) - upper, lower, title, trunc, trimSuffix, replace, quote, squote

## Common mistakes
- Deleting the pipe: the chart installs, but the application now receives `production` instead of `PRODUCTION`.
- Guessing another wrong name (`toUpper`, `upperCase`) - function names are case sensitive.
- Fixing it with a hard-coded `PRODUCTION`: staging would receive the wrong value.

## Helm 3 vs Helm 4
The function set (Go templates + Sprig v3) and the error text are the same on both versions.
