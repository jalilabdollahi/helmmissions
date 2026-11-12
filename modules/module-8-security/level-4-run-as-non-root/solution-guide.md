# Root Is Not Welcome — Walkthrough

1. `kubectl get pods -n helmissions` shows `CreateContainerConfigError`.
2. `kubectl describe pod -n helmissions -l app.kubernetes.io/instance=status-page` ends with
   `Error: container has runAsNonRoot and image will run as root`.
3. The chart sets `podSecurityContext.runAsNonRoot: true` (good) but uses the stock `nginx` image, which starts as root.
4. Edit `status-page/values.yaml`:
   ```yaml
   image:
     repository: nginxinc/nginx-unprivileged
   containerPort: 8080
   ```
   (the unprivileged image runs as UID 101 and listens on 8080; the Service still exposes 80 and targets the named port).
5. `helm upgrade status-page ./status-page -n helmissions --wait`
6. Verify: `kubectl exec deploy/status-page -n helmissions -- id -u` prints 101; run `check`.
