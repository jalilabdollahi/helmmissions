# No Repository Definition

## What broke
`statuspage/Chart.yaml` refers to its dependency repository as `"@hm-stable"`. That alias exists only in the
`repositories.yaml` of the engineer who wrote the chart. On a fresh workstation or CI runner no repository with that name has been
registered, so `helm dependency update` has no URL to fetch from and stops with `no repository definition for @hm-stable`.

## Why Helm behaves this way
Helm keeps a per-user list of named repositories (`helm repo add <name> <url>`) in its config directory, together with a
cached `index.yaml` for each. `repository: "@name"` (or the equivalent `alias:name`) is shorthand that is resolved
against this local list when dependencies are fetched. The URL form is self-contained, but needs no registration only for
`helm dependency update`; `helm dependency build` insists that URL repositories be known (`helm repo add`) as well.
The resolved value that ends up in `Chart.lock` keeps the alias, so a lock produced on one machine cannot be rebuilt on a machine
without the same alias.

## The fix
Register the repository under the exact alias (`helm repo add hm-stable <url>`), then `helm dependency update`.
Or write the URL into `Chart.yaml` and be independent of anyone's local configuration.

## In real life
Aliases are convenient for developers and a recurring headache for CI: the pipeline image has no repo list. Teams either
commit the URL (portable, no setup), or add an explicit `helm repo add` step with credentials before
`helm dependency build`. Private repositories add `--username/--password` or an OCI registry login on top, and cached indexes may need
`helm repo update` when a new chart version was just published.

## Commands worth remembering
- `helm repo list` / `helm repo add <name> <url>` / `helm repo remove <name>`
- `helm repo update` — refresh cached indexes
- `helm search repo <name>/<chart> --versions` — what a repo offers
- `helm dependency update ./chart` / `helm dependency build ./chart`

## Common mistakes
- Adding the repository under a different name than the one in Chart.yaml (`hm-platform` vs `@hm-stable`).
- Downloading the tarball with curl into `charts/`: it installs, but there is no lock and nothing reproducible.
- Forgetting `helm repo update` after publishing a new version, so the constraint resolves to the old one.

## Helm 3 vs Helm 4
Same error text and the same alias mechanism. Helm 4 prints its log lines as `level=INFO msg=...` instead of Helm 3's
plain text, which matters only if you scrape output.
