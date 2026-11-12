# Migrations Before The Database

## What broke
`order-service` prepares its database with two pre-install hook Jobs: `db-init` (create the schema) and `db-migrate`
(apply migrations to it). Their `helm.sh/hook-weight` annotations were `"10"` and `"0"`. Helm runs hooks of one phase in
**ascending** weight order, so the migration ran first, found no schema, exited with an error and failed the whole install.
The init Job was perfectly healthy; it simply never got its turn.

## Why Helm behaves this way
Within a phase (for example `pre-install`) Helm sorts the hook manifests by weight, then by resource kind (install order), then
by name, and runs them one after the other: it creates a hook and waits for it to be ready or complete before starting the next
one. Without any weight the value is `0`, so unweighted hooks fall back to kind and alphabetical order, which is fragile and
easy to break by renaming a file. Weights may be negative, and they are compared as numbers (they must be
quoted strings in YAML). Hooks with the same weight are *not* guaranteed to run in the order you wrote them.

## The fix
Give the prerequisite a lower weight than its dependant: init `-5`, migrate `0`, for example, or push the migration to `20`.
Keep ServiceAccount and Role hooks lowest of all, they must exist before the Jobs that use them. After fixing the
chart, upgrade or reinstall: the Jobs are also `pre-upgrade` hooks, so the failed release can be upgraded in place.

## In real life
Order bugs hide when the hooks happen to sort alphabetically in your favour (`db-init` < `db-migrate`) and appear when someone
renames a file or adds a third hook. Treat the weights as part of the contract: put the reasoning in a comment next to
the annotation, and make dependant hooks fail loudly (like this migration did) rather than silently doing the wrong thing.

## Commands worth remembering
- `helm get hooks <release>` — the hooks and their weights as stored
- `helm template <chart> --show-only templates/<file>` — render a single hook
- `kubectl get jobs --sort-by=.metadata.creationTimestamp` — the order in which hook Jobs were actually created

## Common mistakes
- Believing that file or resource names decide the order (they only break ties after weight and kind).
- Assuming a higher weight runs first.
- Creating the missing state by hand with `kubectl` so the migration passes: the next fresh install fails the same way.

## Helm 3 vs Helm 4
Identical: ascending weight, then kind, then name, and each hook is awaited before the next starts. Helm 4's failure message
for the migration Job reads `failed pre-install: resource Job/<ns>/<name> not ready. status: Failed`.
