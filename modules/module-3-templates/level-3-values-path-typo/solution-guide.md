# Empty Image - Walkthrough

1. See the symptom:
   ```bash
   kubectl get pods -n helmissions          # InvalidImageName
   kubectl describe pod -n helmissions -l app.kubernetes.io/instance=receipts | grep -i -A3 "image"
   kubectl get deploy receipts-api -n helmissions -o jsonpath='{.spec.template.spec.containers[0].image}'
   # :1.27-alpine
   ```
2. The release is fine as far as Helm is concerned: `helm status receipts` is `deployed`, and
   `helm get manifest receipts | grep image:` shows the same broken value. The bug is in the chart.
3. `grep -rn "image\." receipts/templates` shows `.Values.image.respository`; `values.yaml` has `repository`.
   A missing key is `nil`, and nil prints as an empty string, so the image became `":1.27-alpine"`.
4. Fix the spelling in `templates/deployment.yaml`, check with `helm template receipts ./receipts | grep image:`.
5. Roll it out and verify:
   ```bash
   helm upgrade receipts ./receipts -n helmissions --wait
   helm history receipts -n helmissions
   kubectl get pods -n helmissions
   ```
