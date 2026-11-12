# Ship A Clean Package

## What broke
Nothing failed - which is the danger. `helm package` happily bundled `secrets.local.env`, backup copies and a
scratch `tmp/` folder into the chart archive. Published to a shared repository, that archive would have leaked
credentials and data to everyone who can pull the chart.

## Why Helm behaves this way
A chart is "whatever is in the directory". `helm package` creates a gzipped tarball of the whole chart
directory, skipping only what `.helmignore` lists (the same idea as `.gitignore`; `helm create` scaffolds
one with sensible defaults, hand-made charts often have none). Helm cannot know that a file is private - it only
knows that it sits in the chart root. `.helmignore` is also honoured by `helm install ./dir` and `helm lint`, so
ignored files never reach the release either.

## The fix
Add a `.helmignore` with the local-only patterns, package into `dist/`, inspect the archive with `tar tzf`, and install
from the `.tgz` so that what you deploy is exactly what you would publish. Deleting the junk files first also works but
only for this one working copy; `.helmignore` protects every future packager.

## In real life
Chart repositories and OCI registries are shared, long-lived and mirrored: a secret that was published once must be
rotated. Teams therefore (1) commit a `.helmignore`, (2) keep secrets out of the chart directory altogether, and (3)
add a CI step that lists the package contents (`tar tzf`) and fails on unexpected files. Packaging in a clean
checkout (CI) rather than a developer's laptop avoids most of this.

## Commands worth remembering
- `helm package ./chart -d dist` - build `chart-<version>.tgz` into `dist/`
- `tar tzf dist/<chart>-<version>.tgz` - list the package contents
- `helm install <rel> dist/<chart>-<version>.tgz` - install from the archive
- `helm show chart dist/<chart>-<version>.tgz` - inspect without unpacking

## Common mistakes
- Assuming `.gitignore` is respected: Helm only reads `.helmignore`.
- Writing a pattern that does not match (`tmp` vs `tmp/`, `*.env` vs `secrets.local.env` is fine, a leading path is not).
- Never looking inside the archive before publishing it.

## Helm 3 vs Helm 4
Same behaviour for `.helmignore` and `helm package` in both versions; the archive name is `<name>-<version>.tgz`.
