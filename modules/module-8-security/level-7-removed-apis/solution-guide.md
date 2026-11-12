# Removed APIs — Walkthrough

1. Reproduce: `helm upgrade --install inventory ./inventory-service -n helmissions` fails with
   `no matches for kind "PodDisruptionBudget" in version "policy/v1beta1"` (and the same for the HPA).
2. Check what the server offers: `kubectl api-versions | grep -E 'policy|autoscaling'` lists `policy/v1`,
   `autoscaling/v1` and `autoscaling/v2` — no `v1beta1` / `v2beta2`.
3. Find the stale versions: `grep -rn "^apiVersion" inventory-service/templates`.
4. Edit `templates/pdb.yaml` -> `policy/v1`; `templates/hpa.yaml` -> `autoscaling/v2`. The spec fields used here
   (`minAvailable`, `selector`, `scaleTargetRef`, `metrics[].resource.target`) are identical.
5. `helm upgrade --install inventory ./inventory-service -n helmissions --wait`
6. Verify: `kubectl get pdb,hpa -n helmissions`; run `check`.
