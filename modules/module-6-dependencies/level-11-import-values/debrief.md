# Parent Needs Child's Value

## What broke
The parent asked Helm to import `service.port` from `pg-lite` into `db.port`. `import-values` only moves tables (maps),
and `service.port` is a plain number, so Helm logged a warning (`"port" is not a table`), imported nothing, and the
parent's `required` check failed. Without that `required`, the API would have started with an empty DB_PORT.

## Why Helm behaves this way
`import-values` lets a parent pull values *up* from a subchart, the reverse of normal scoping. It has two forms.
The string form (`- data`) imports the subchart's `exports.data` table into the parent's root values, so a subchart author
can publish a stable set of values on purpose. The explicit form (`- child: service`, `parent: db`) copies any table from the subchart
into any parent path. In both cases a scalar cannot be imported on its own: wrap it in a table, or import the table that contains it.
Two more details matter: imported values are read from the subchart's *defaults* (its `values.yaml`), not from overrides such
as `--set pg-lite.service.port=...`; and the parent's own values win over imported ones. Import happens when the chart is loaded, so the
packaged subchart in `charts/` is what is read, and the lock's digest includes the `import-values` declaration.

## The fix
Import the table that holds the port (`child: service`, `parent: db`) and refresh the dependency. The template's `.Values.db.port` now
follows the subchart. Hard-coding `db.port: 5432` in the parent, or inventing a second copy of the number in the subchart, renders but drifts as soon as the
database port changes.

## In real life
Parents typically need the subchart's service name, port or secret name. `import-values` avoids duplicating those facts, but it fails
quietly, and only a warning reaches the log; pipelines that hide stderr never see it. Use `required` in the parent template (as
here) so a missing import breaks the render instead of the pod, and check `helm template` output in CI.
Alternatively, read the subchart's value directly with `index .Values "pg-lite" "service" "port"`, which also honours overrides.

## Commands worth remembering
- `helm template r ./chart` — read the warnings printed before the error
- `helm show values ./chart/charts/<sub>.tgz` — the table structure you can import from
- `helm get values <rel> --all` — the merged result, including imported values
- `helm dependency update ./chart` — re-package after changing a declaration

## Common mistakes
- Importing a scalar path (`child: service.port`): only tables can be imported.
- Expecting overrides of the subchart's values to flow through the import: only its defaults are imported.
- Hard-coding the number in the parent "to make it work".

## Helm 3 vs Helm 4
The behaviour is the same. Helm 4 logs the problem as `level=WARN msg="ImportValues missing table from chart"` where Helm 3 printed
`Warning: ImportValues missing table: ...`; both are easy to miss in CI output.
