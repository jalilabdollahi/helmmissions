# Roll It Back - Walkthrough

1. See what is wrong with the pod:
   ```bash
   kubectl get pods -n helmissions          # ErrImagePull / ImagePullBackOff
   kubectl describe pod -n helmissions -l app.kubernetes.io/name=quotes-api | grep -A3 -i image
   ```
2. Look at the release history:
   ```bash
   helm history quotes-api -n helmissions
   # 1  superseded  Install complete
   # 2  deployed    Upgrade complete
   ```
   Revision 2 is "deployed" because Helm applied it successfully - Helm does not know the image can't be pulled.
3. Compare the two revisions if you want proof:
   ```bash
   helm get values quotes-api -n helmissions --revision 2    # image.tag: v1.10.1-rc1
   helm get values quotes-api -n helmissions --revision 1    # (defaults, v1.10)
   ```
4. Roll back to revision 1:
   ```bash
   helm rollback quotes-api 1 -n helmissions --wait
   helm history quotes-api -n helmissions
   # 3  deployed  Rollback to 1
   ```
5. Verify: `kubectl get pods -n helmissions` shows a Ready pod and the Service has endpoints.
6. Run `check` in the game.
