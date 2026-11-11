# No Repository Definition — Walkthrough

1. Reproduce:
   ```bash
   cd sandbox/current
   helm dependency update ./statuspage
   # Error: no repository definition for @hm-stable. Please add them via 'helm repo add'
   helm repo list              # no repositories (or none called hm-stable)
   ```
2. Find the repository URL in `README.txt` and register it under the alias the chart uses:
   ```bash
   helm repo add hm-stable http://localhost:8879/m6-repo-not-added
   helm search repo hm-stable/uptime-probe --versions
   ```
3. Resolve and install:
   ```bash
   helm dependency update ./statuspage      # Chart.lock pins uptime-probe 1.4.0
   helm install statuspage ./statuspage -n helmissions --wait
   ```
4. Run `check`.

Alternative: replace `"@hm-stable"` in `Chart.yaml` with the repository URL; `helm dependency update` accepts
unmanaged URLs (but `helm dependency build` does not).
