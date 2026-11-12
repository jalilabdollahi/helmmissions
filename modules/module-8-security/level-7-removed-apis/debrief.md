# Removed APIs

## What broke
After the cluster upgrade, the API server no longer serves `policy/v1beta1` PodDisruptionBudget or
`autoscaling/v2beta2` HorizontalPodAutoscaler. Helm builds every object of the rendered manifest through the API's
REST mapping before it applies anything, so one unknown kind/version aborts the whole install:
`no matches for kind ... in version ...`. The hint "ensure CRDs are installed first" is generic; no CRD is
involved here.

## Why Helm behaves this way
Kubernetes deprecates API versions on a published schedule and removes them in a later minor release
(PDB `v1beta1` in 1.25, HPA `v2beta2` in 1.26). Helm templates are just text, so a chart keeps rendering the old
`apiVersion` forever and only fails when it meets a server that dropped it. There is no automatic conversion for
new installs or upgrades. Releases that already exist are an even nastier case, because their *stored* manifest
still contains the removed version (that is the `helm-mapkubeapis` plugin's job).

## The fix
Move each manifest to the version the server serves (`policy/v1`, `autoscaling/v2`), check the fields still mean the
same thing, and install. Where a chart must support old and new clusters, select the version with
`.Capabilities.APIVersions.Has "policy/v1"`.

## In real life
Cluster upgrades are scheduled by the platform team while charts belong to dozens of app teams, so removals show up as a
broken deploy on a Monday. Scan before the upgrade: `kubectl get --raw /metrics | grep apiserver_requested_deprecated_apis`,
tools such as Pluto, `kubent` or `kubectl convert`, and `helm template | kubeconform -kubernetes-version 1.37.0` in CI.
Deleting the "problem" resource (the PDB or the HPA) gets the pipeline green but quietly removes protection from voluntary
disruptions and load.

## Commands worth remembering
- `kubectl api-versions` / `kubectl api-resources` — what this server actually serves
- `kubectl explain poddisruptionbudget --api-version=policy/v1`
- `helm template ./chart | grep -n '^apiVersion'`
- `helm plugin install https://github.com/helm/helm-mapkubeapis` — fix stored release manifests (when the release already exists)

## Common mistakes
- Deleting the PDB/HPA templates instead of migrating them.
- Updating only one of the two stale resources and being surprised by the second error.
- Assuming "ensure CRDs are installed first" means a CRD is missing.
- Testing only against an old local cluster: render against the version you will run.

## Helm 3 vs Helm 4
The error is the same on both: Helm resolves every object's kind through the API server's REST mapping before it applies
anything. Note that a failed *first* install of this kind stores no release at all (no `failed` record), so
`helm upgrade --install` works again as soon as the chart is fixed. Helm 4 applies new releases with server-side apply, but
that never gets the chance to run for a kind that does not exist.
