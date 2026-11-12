# Solution guide - Unable To Build Kubernetes Objects

1. `helm upgrade edge-gateway ./edge-gateway -n helmissions` -> `resource mapping not found ... no matches for kind "PodDisruptionBudget" in version "policy/v1beta1"`:
   the *chart* in the workspace uses removed API versions. Once the chart is fixed, the next attempt reports `unable to build kubernetes objects from current release manifest` with the same kind of mapping error - "current release manifest" is the manifest stored in the last revision, so the release record has the same problem. (Do not try `helm rollback` to get out: it fails the same way and leaves a `pending-rollback` revision behind.)
2. `helm get manifest edge-gateway -n helmissions | grep apiVersion` confirms `policy/v1beta1` and `autoscaling/v2beta1`.
   The live objects are fine (the cluster converted them long ago); only the record is stale.
3. Patch the record of the latest revision N (`helm history`): `kubectl get secret sh.helm.release.v1.edge-gateway.vN -o json`,
   `.data.release` -> base64 decode -> base64 decode -> gunzip -> JSON; replace the two apiVersions in `.manifest`; gzip -> base64 -> base64;
   `kubectl patch secret ... --type=merge -p '{"data":{"release":"..."}}'`.
4. Retry the upgrade: a new error - the chart's own templates still say `policy/v1beta1` / `autoscaling/v2beta1`. Change them to `policy/v1` and
   `autoscaling/v2`; in v2 the metric target is `target: {type: Utilization, averageUtilization: 80}` (the old `targetAverageUtilization` is an unknown field).
5. Next error: the HPA rejects `minReplicas: 4` with `maxReplicas: 2`. Set min 2 / max 4 in values.yaml.
6. `helm upgrade edge-gateway ./edge-gateway -n helmissions --wait`: revision 3, history preserved. `curl http://edge-gateway/`.
