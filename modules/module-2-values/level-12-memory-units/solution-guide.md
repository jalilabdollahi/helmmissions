# 256 Bytes Of RAM - Walkthrough

1. See what happened:
   ```bash
   helm history image-resizer -n helmissions     # revision 1 failed
   helm status image-resizer -n helmissions
   # ... requests: Invalid value: "128Mi": must be less than or equal to memory limit of 256
   ```
2. In `image-resizer/values.yaml` the limit is a bare number: `memory: 256`. Kubernetes reads that as 256 bytes.
   The 128Mi request is larger than the limit, which the API rejects.
3. Add the unit:
   ```yaml
   limits:
     memory: 256Mi
   ```
4. `helm upgrade image-resizer ./image-resizer -n helmissions` (upgrading a failed first revision is fine).
5. Verify: `kubectl get pods -n helmissions` and
   `kubectl get deploy image-resizer -n helmissions -o jsonpath='{.spec.template.spec.containers[0].resources}'`.
6. Run `check`.
