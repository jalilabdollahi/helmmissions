# OCI Reference Format — Walkthrough

1. Reproduce (note `--plain-http`; without it Helm tries HTTPS against a plain-HTTP registry):
   ```bash
   cd sandbox/current
   helm dependency update ./booking --plain-http
   # ... localhost:5001/m6-oci-dependency-url/charts/seat-cache/seat-cache:2.0.1: not found
   ```
2. Confirm the artifact exists at the shorter path:
   ```bash
   helm show chart oci://localhost:5001/m6-oci-dependency-url/charts/seat-cache --version 2.0.1 --plain-http
   ```
3. Fix `booking/Chart.yaml`:
   ```yaml
   dependencies:
     - name: seat-cache
       version: 2.0.1
       repository: oci://localhost:5001/m6-oci-dependency-url/charts
   ```
4. Resolve and install:
   ```bash
   helm dependency update ./booking --plain-http
   helm install booking ./booking -n helmissions --wait
   ```
5. Run `check`.
