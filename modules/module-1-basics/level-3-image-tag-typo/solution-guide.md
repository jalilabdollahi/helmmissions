# Pull Backoff - Walkthrough

1. See the symptom:
   ```bash
   kubectl get pods -n helmissions          # ErrImagePull / ImagePullBackOff
   kubectl describe pod -n helmissions -l app=ledger-api | tail -15
   # Failed to pull image "nginx:1.27-alpien": ... not found
   ```
2. Find where the image comes from. Helm built it from `image.repository` and `image.tag`:
   ```bash
   helm get values ledger-api -n helmissions --all | grep -A3 image
   grep tag ledger-api/values.yaml           # tag: 1.27-alpien   <- typo
   ```
3. Fix `ledger-api/values.yaml`: `tag: 1.27-alpine`.
4. Roll it out through Helm so the release matches the file:
   ```bash
   helm upgrade ledger-api ./ledger-api -n helmissions --wait
   helm history ledger-api -n helmissions   # revision 2, deployed
   kubectl get pods -n helmissions          # 2/2 Running
   ```
5. Run `check` in the game.
