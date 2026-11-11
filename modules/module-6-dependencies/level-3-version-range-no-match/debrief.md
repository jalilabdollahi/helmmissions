# No Matching Version

## What broke
`searchdesk` asked for `redis-lite` `^2.0.0`, but the repository only publishes the 1.2.x line. When
`helm dependency update` downloads the repository index and applies the constraint to the versions listed there, no
version qualifies, so Helm stops with `can't get a valid version for 1 subchart(s)`. Note that the repository itself was
perfectly healthy: the index loaded, the chart name exists, only the constraint is unsatisfiable.

## Why Helm behaves this way
Dependency `version` is a SemVer *constraint*, not a version. `^1.2.0` is `>=1.2.0 <2.0.0`; `~1.2.0` is
`>=1.2.0 <1.3.0`; `1.2.x`, `>=1.2 <1.4` and `*` are valid too; a bare `1.2.3` pins one release. `helm dependency update`
picks the highest version in the index that satisfies the constraint and records the concrete result, with a digest,
in `Chart.lock`. Later `helm dependency build` runs reproduce that choice, so a range in `Chart.yaml` never changes
what you deploy until someone runs `update` again.

## The fix
Look at what the repository serves (`helm search repo <repo>/<chart> --versions`, or read `index.yaml`) and pick a
constraint it can satisfy: `~1.2.0` here. Run `helm dependency update`, commit `Chart.lock`, install.

## In real life
Constraints go stale when a team writes `^2.0.0` against a chart that is still on the way (an unreleased major) or
when a repository is rebuilt without the version a chart was developed against. Pre-release versions need an explicit
`-0` suffix in the constraint (`>=2.0.0-0`) to be considered. Prefer `~` for infrastructure dependencies, where minors
can change behaviour, and reserve `^` for charts with a strong compatibility policy.

## Commands worth remembering
- `helm search repo <repo>/<chart> --versions` — every version the repo index offers
- `helm show chart <repo>/<chart> --version 1.2.3` — inspect before depending on it
- `helm dependency update ./chart` — resolve constraints and write `Chart.lock`
- `helm dependency list ./chart` — declared constraints and their status

## Common mistakes
- Deleting the dependency to get past the error: the release then has no cache at all.
- Treating `^1.2` as "exactly 1.2": it is a range and may resolve to 1.9.x later.
- Forgetting that a lock file records the resolved version: changing the constraint without `update` changes nothing.

## Helm 3 vs Helm 4
Same error text and same SemVer handling. Repositories referenced by URL work in both versions without `helm repo add`
(Helm reports them as "unmanaged repositories"); an `@alias` reference requires the repository to be added first.

`helm dependency build` has one more requirement than `update`: it refuses to fetch from a repository URL that is
not in your `helm repo list` (`no repository definition for <url>`), while `update` tolerates unmanaged URLs.
