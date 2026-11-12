# Cannot Re-use a Name - Walkthrough

1. See what is running:
   ```bash
   helm list -n helmissions            # orders  1  deployed  orders-0.1.0
   helm history orders -n helmissions
   ```
2. `helm install orders ./orders` fails because the name belongs to a live release. `install` only creates.
3. Upgrade the release to the new chart:
   ```bash
   helm upgrade orders ./orders -n helmissions --wait
   helm history orders -n helmissions
   # 1  superseded  orders-0.1.0
   # 2  deployed    orders-0.2.0
   ```
4. Verify the new ConfigMap and pods: `kubectl get cm,pods -n helmissions`.
5. Run `check` in the game.
