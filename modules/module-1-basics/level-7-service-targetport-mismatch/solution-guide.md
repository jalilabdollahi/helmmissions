# Connection Refused - Walkthrough

1. Prove the symptom and rule out the usual suspects:
   ```bash
   kubectl get pods,endpoints -n helmissions      # pods Ready, endpoints populated
   kubectl run t --rm -it --image=curlimages/curl:8.10.1 --restart=Never -n helmissions -- curl -sv inventory
   # Connection refused
   ```
2. Compare the ports:
   ```bash
   kubectl get svc inventory -n helmissions -o jsonpath='{.spec.ports}'    # targetPort 8080
   kubectl get deploy inventory -n helmissions -o jsonpath='{.spec.template.spec.containers[0].ports}'  # 80
   ```
   Endpoints exist because they are built from the selector and pod readiness, not from the port.
3. The Service's `targetPort` comes from `service.targetPort` in `inventory/values.yaml`. Set it to `80`.
4. Upgrade through Helm so release and chart match:
   ```bash
   helm upgrade inventory ./inventory -n helmissions --wait
   ```
5. Re-test the request; run `check` in the game.
