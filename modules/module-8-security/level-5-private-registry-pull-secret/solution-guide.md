# Unauthorized Pull — Walkthrough

1. `kubectl get pods -n helmissions` shows `ErrImagePull` / `ImagePullBackOff`.
2. `kubectl describe pod -n helmissions -l app.kubernetes.io/instance=portal` ends with
   `... pull access denied, repository does not exist or may require authorization: authorization failed: no basic auth credentials`.
   The repository exists (the ticket says so) — the registry just wants credentials.
3. Create the pull Secret from the ticket's account, for exactly the registry host in the image reference:
   ```bash
   kubectl create secret docker-registry regcred -n helmissions \
     --docker-server=localhost:5002 --docker-username=depot --docker-password='Ship-It-2026'
   ```
4. Reference it from the chart values (the chart already renders it into the pod spec):
   ```yaml
   imagePullSecrets:
     - name: regcred
   ```
5. `helm upgrade portal ./partner-portal -n helmissions --wait`
6. `kubectl get pods -n helmissions` — 2/2 Ready. Run `check`.

(Attaching the Secret to the namespace's `default` ServiceAccount also works, but keeping it in the chart makes the
dependency visible.)
