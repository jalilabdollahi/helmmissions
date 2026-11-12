# No Matches For Kind

## What broke
The chart placed a CustomResourceDefinition and an instance of that custom resource side by side in
`templates/`. On a cluster where the CRD does not exist yet, Helm cannot even map the kind `BackupSchedule` to an
API endpoint, so the install aborts before creating anything: `no matches for kind ... ensure CRDs are installed first`.

## Why Helm behaves this way
Helm renders all templates, sorts them by kind and then builds the Kubernetes objects for the whole release in one
step, discovering each kind through the API server's REST mapping. A CRD that is part of the same batch cannot
have been registered at that time. The `crds/` directory exists to solve this: its files are applied first, Helm
waits until they are Established, and only then are templates rendered and installed. The trade-offs are
deliberate: files in `crds/` are not templated, are installed only on `helm install` (never upgraded or deleted by Helm),
and are not part of the release manifest, because CRD changes can destroy data.

## The fix
Move the CRD to `backup-scheduler/crds/`. Alternatives: install the CRD separately (kubectl, a separate chart
or a pipeline step) and ship only the custom resources in the chart, or use a hook for one-time creation.

## In real life
Operators (cert-manager, Prometheus Operator, Argo, Crossplane) ship CRDs separately for exactly this reason,
and upgrading them is its own procedure, since `helm upgrade` never touches `crds/`. Charts that both define and use a CRD
are common in internal platforms; the first install on a fresh cluster is the case that gets forgotten
in testing because the CRD already exists in staging.

## Commands worth remembering
- `kubectl get crd | grep <group>` — is the kind registered?
- `kubectl api-resources --api-group=<group>` — what the API server knows
- `helm install --skip-crds` — install without the `crds/` directory
- `helm show crds <chart>` — print the CRDs a chart would install

## Common mistakes
- Adding `{{ }}` templating to files in `crds/` — they are not rendered.
- Expecting `helm upgrade` to update a CRD that lives in `crds/` (see the CRD upgrade level in the Rollbacks module).
- Removing the custom resource from the chart to make the error go away.

## Helm 3 vs Helm 4
The error and the `crds/` behaviour are the same. Helm 4's wording of the REST-mapping error is unchanged;
note that nothing is created (no failed release record) because the failure happens before the release is applied.
