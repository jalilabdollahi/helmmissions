# Policy Blocks The Frontend — Walkthrough

1. Symptom: the frontend log says `catalog unreachable (timeout)` while the backend is Running:
   ```bash
   kubectl logs deploy/shopfront-frontend -n helmissions
   kubectl get endpointslices -n helmissions
   ```
   A timeout (not "connection refused", not a DNS error) is how a NetworkPolicy drop looks.
2. Inspect policies and labels:
   ```bash
   kubectl get networkpolicy -n helmissions
   kubectl describe networkpolicy shopfront-allow-web-to-backend -n helmissions
   kubectl get pods -n helmissions --show-labels
   ```
   The policy admits pods labelled `app.kubernetes.io/component=web`; the frontend pod is labelled
   `app.kubernetes.io/component=frontend`.
3. Edit `shopfront/templates/networkpolicy.yaml`: change the `from.podSelector` label value to `frontend`.
   (Relabelling the pod template to `web` is equally valid — what matters is that they agree.)
4. `helm upgrade shopfront ./shopfront -n helmissions --wait`
5. Verify the allowed path works (frontend turns Ready) and the blocked path still blocks:
   ```bash
   kubectl run probe -n helmissions --rm -it --restart=Never --image=curlimages/curl:8.10.1 -- curl -m 4 http://shopfront-backend
   # times out
   ```
6. Run `check`.
