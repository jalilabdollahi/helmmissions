# %!d(float64=8080)

## What broke
`printf "%d" .Values.port` rendered `%!d(float64=8080)` into the container's `--port` argument. The application
refused to parse that, and the pod crash-looped, while Helm happily reported `deployed`.

## Why Helm behaves this way
Go's `fmt` does not panic on a bad verb: it prints an error marker of the form `%!verb(type=value)` and carries
on. Helm renders the chart successfully; the garbage is simply part of the manifest. The type is `float64` because
values files are parsed as JSON-like documents in which every number is a float64 - the integer 8080 and the float
8080.0 are the same thing. Values supplied on the command line with `--set port=8080` are parsed differently and
arrive as int64, so `%d` happens to work there. The same chart therefore passes with `--set` and fails with a values
file, which is exactly the kind of difference between a laptop and CI that wastes an afternoon.

## The fix
Use `%v` when you only need the number printed, or `int` when the integer type matters (`printf "%d" (int .Values.port)`,
or just `{{ .Values.port | int }}`). Remember that very large numbers (1e6 and above) print in scientific notation
with `%v` on a float64 - convert with `int` (or `int64`) for those.

## In real life
Search a chart for the marker with `helm template ... | grep '%!'` - it appears for `%d` on floats, `%s` on numbers
(`%!s(float64=...)`) and missing arguments (`%!d(MISSING)`). A one-line CI check that fails when the rendered output
contains `%!` catches the whole family.

## Commands worth remembering
- `helm template ./chart | grep '%!'` - find formatting accidents
- `kubectl logs <pod> --previous` - the crashed container's last words
- `kubectl get deploy <name> -o jsonpath='{.spec.template.spec.containers[0].args}'`

## Common mistakes
- Passing the port with `--set` on the upgrade: it works once, and the next person's values file breaks it again.
- Hard-coding the number in the template.
- Converting with `toString` and then using `%d` - strings are not integers either.

## Helm 3 vs Helm 4
Number handling for values files is identical (float64). Both versions render the `%!d(...)` marker without an error.
