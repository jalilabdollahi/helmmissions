# Stale Index

## What broke
The release job copied a new chart tarball into the repository folder but never regenerated `index.yaml`. A classic
Helm repository is nothing more than static files: Helm clients download `index.yaml`, look the chart version up in it
and only then fetch the tarball from the `urls` of that entry. A tarball the index does not mention is invisible, no matter
how often anyone runs `helm repo update`.

## Why Helm behaves this way
`helm repo index DIR` generates the index by globbing the tarballs in the directory (top level and one level below),
loading each chart's metadata and computing its SHA-256 digest. Without `--merge` the new index contains only what it found,
so versions whose tarballs live elsewhere (an archive folder, another bucket) vanish from it. With `--merge old-index.yaml`,
entries that already exist are kept as they are and new ones are added, which makes the operation append-only. `--url` sets
the absolute URL prefix for new entries; without it the URLs are relative and Helm resolves them against the repository URL.
The `digest` is what lets clients and mirrors detect a modified tarball, so entries must never be typed by hand.

## The fix
Regenerate with `helm repo index repo --url REPO_URL --merge repo/index.yaml`, check that every version is still listed, run
`helm repo update`, then install or upgrade with `--version`.

## In real life
Self-hosted repositories on S3/GCS/nginx (and ChartMuseum before OCI) hit this constantly: CI uploads the tarball, a second
job (or a human) forgets the reindex, or two pipelines overwrite each other's `index.yaml`. Robust setups publish tarball
and index in one atomic step, serialise publishers, `--merge` instead of regenerating, set cache headers so clients don't see
a stale index for hours, and run a smoke test (`helm pull repo/chart --version X`) after every publish. OCI registries remove
the index problem entirely, because tags are listed by the registry itself.

## Commands worth remembering
- `helm repo index DIR --url URL --merge DIR/index.yaml` — add new tarballs, keep existing entries
- `helm repo update` — refresh the local copy of the served index
- `helm search repo NAME --versions` — what the cached index offers
- `helm pull repo/chart --version X` — prove a version is downloadable

## Common mistakes
- Regenerating without `--merge`: retired versions disappear and everyone pinned to them breaks.
- Editing `index.yaml` by hand (copied entries, wrong digests): works until someone verifies the digest or a mirror syncs.
- Running `helm repo update` and expecting it to fix the server: it only refreshes the client cache.

## Helm 3 vs Helm 4
Identical in both: `helm repo index`, `--merge` and `--url` behave the same, and the error text for a missing version is the same
(`chart "x" matching 1.3.0 not found in REPO index`). Helm 4 additionally caches repository content under
`HELM_CONTENT_CACHE`/`HELM_CACHE_HOME`, but `helm repo update` refreshes it as before.
