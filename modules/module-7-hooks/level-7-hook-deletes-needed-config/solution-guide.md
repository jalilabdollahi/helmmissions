# The Config That Hooked Itself Away — Walkthrough

1. Diagnose the stuck pod:
   ```bash
   kubectl get pods -n helmissions                  # ContainerCreating
   kubectl describe pod -l app.kubernetes.io/name=route-gateway -n helmissions | tail -5
   # MountVolume.SetUp failed for volume "routes" : configmap "gateway-routes" not found
   ```
2. Check what Helm thinks it manages:
   ```bash
   helm get manifest gateway -n helmissions         # Deployment and Service only
   helm get hooks gateway -n helmissions            # the ConfigMap, with hook-succeeded
   ```
   The ConfigMap was created in `pre-install`, counted as a successful hook immediately, and deleted by `hook-succeeded` before the
   Deployment was even created.
3. Edit `route-gateway/templates/routes-configmap.yaml` and remove the three `helm.sh/hook*` annotations.
4. Upgrade and verify:
   ```bash
   helm upgrade gateway ./route-gateway -n helmissions --wait
   helm get manifest gateway -n helmissions | grep -A2 'kind: ConfigMap'
   kubectl get pods -n helmissions
   ```
5. Run `check`.
