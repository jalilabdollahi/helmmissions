# 1.048576e+06

## What broke
`maxUploadBytes: 1048576` is a perfectly good YAML integer, but when the chart printed it with `{{ .Values.maxUploadBytes }}`
the proxy received `1.048576e+06`. The application, which expects digits only, refused to start.

## Why Helm behaves this way
Helm converts YAML values files to JSON and decodes them into Go maps. JSON has a single number type, so every number that
comes from a values file becomes a `float64`. When a float64 is printed by a template, large whole numbers come out in exponent notation (observed on Helm 4.3: 1048576 prints as 1.048576e+06).
 Values
set with `--set` are parsed by Helm itself as `int64`, so the same number can print differently depending on *how it was supplied* -
which is why the bug appears in one environment and not another.

## The fix
Convert in the template: `{{ .Values.maxUploadBytes | int64 | quote }}` (or `int`, or `printf "%d" (int ...)`). Quoting the
value inside `values.yaml` makes that file work but not every override: another team's `maxUploadBytes: 5242880` is a number again.
Fix the chart once, so every environment benefits.

## In real life
Byte sizes, epoch timestamps, ports above 999999, IDs and counters all cross the million mark. Symptoms vary: env vars with
`e+06` in them, nginx or Java refusing a config, ConfigMaps whose numbers silently lose precision (floats only have 53 bits of
mantissa, so integers beyond 2^53 are corrupted). Treat identifiers and very large numbers as strings in values files and
pass them through `quote`; use `int64` for sizes.

## Commands worth remembering
- `helm template ./chart -f override.yaml | grep KEY` - verify the rendering for each source of values
- `helm get values <rel> -o json` - JSON output reveals the stored type
- `{{ typeOf .Values.x }}` in a template (with `--debug`) - shows float64 vs int64 vs string

## Common mistakes
- Quoting the number in the default `values.yaml` and calling it fixed.
- Testing only with `--set` (int64) and shipping a chart that breaks with values files (float64).
- Using `toString` on the float: it prints the same scientific notation.

## Helm 3 vs Helm 4
Verified on Helm 4.3: numbers from values files are float64 and render as `1.048576e+06`; `--set` numbers are int64. Helm 3 behaves the same.
