# Values Not Reaching The Subchart — Walkthrough

1. Look at the live state: `kubectl get deploy -n helmissions` shows `newsroom-image-resizer 1/1`.
2. Look at what Helm computed:
   ```bash
   cd sandbox/current
   helm get values newsroom -n helmissions --all
   ```
   The `resizer:` block shows up as an ordinary parent value, while `image-resizer:` holds only the subchart defaults
   (replicaCount 1, maxWidth 1024).
3. The dependency is named `image-resizer` in `Chart.yaml`; only a top-level key with that exact name scopes values to it.
   Rename the block in `newsroom/values.yaml`:
   ```yaml
   image-resizer:
     replicaCount: 3
     maxWidth: 800
     quality: 70
   ```
4. Roll it out and check:
   ```bash
   helm upgrade newsroom ./newsroom -n helmissions --wait
   helm get values newsroom -n helmissions --all | grep -A5 image-resizer
   kubectl get deploy -n helmissions
   ```
5. Run `check`.
