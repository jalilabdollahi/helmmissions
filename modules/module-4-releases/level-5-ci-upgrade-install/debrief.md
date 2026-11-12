# First Deploy Breaks CI

## What broke
`ci/deploy.sh` used plain `helm upgrade`. That verb requires an existing release; on a brand-new
environment there is none, so Helm answers `"shipment-tracker" has no deployed releases` and exits
non-zero. Staging worked only because someone had once installed the release by hand.

## Why Helm behaves this way
Helm separates the lifecycle verbs: `install` creates revision 1 and fails if a release with that name
exists; `upgrade` creates revision N+1 and fails if there is nothing to upgrade from. The release record
(a Secret in the namespace) is what Helm consults to decide which situation applies. `helm upgrade
--install` (short form `-i`) simply looks the release up and picks the right path, so one command is
safe in both situations and when re-run after a failure.

## The fix
Use `helm upgrade --install` in the pipeline. Keep `--namespace`, `--wait` and `--timeout`, and add
`--create-namespace` when the pipeline is also responsible for creating namespaces.

## In real life
Pipelines should be idempotent: the first run, the hundredth run, and a re-run after a crash must all
converge to the same state. "Works in staging" is not proof when staging was bootstrapped manually. Test the
bootstrap path regularly: a throwaway namespace and a green first deploy catch this class of bug long
before a customer environment does.

## Commands worth remembering
- `helm upgrade --install <rel> <chart> -n <ns> --create-namespace --wait`
- `helm status <rel> -n <ns>` — does the release exist?
- `helm list -n <ns> --all-namespaces` — find the release across namespaces

## Common mistakes
- Running `helm install` by hand once to "unblock" the pipeline and leaving the script broken.
- Using `helm install` in the pipeline, which fails on every re-deploy with "cannot reuse a name".
- Forgetting `--namespace` and deploying into whatever namespace the kubeconfig defaults to.

## Helm 3 vs Helm 4
`helm upgrade --install` behaves identically on both. Helm 4's error message is the same
(`has no deployed releases`). One Helm 4 nuance: because new releases use server-side apply by default,
the first `--install` of a chart whose objects already exist from `kubectl` can raise field-manager
conflicts that Helm 3 did not (see the adoption levels).
