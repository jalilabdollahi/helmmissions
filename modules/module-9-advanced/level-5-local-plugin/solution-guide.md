# Plugin Won't Load — Walkthrough

1. Reproduce:
   ```bash
   helm plugin install ./hm-audit
   # Error: fork/exec .../plugins/hm-audit/hooks/install-rules.sh: no such file or directory
   helm plugin list          # hm-audit is listed anyway (half-installed)
   helm hm-audit checkout -n helmissions
   # Error: fork/exec .../plugins/hm-audit/bin/audit.sh: no such file or directory
   ```
2. Compare `hm-audit/plugin.yaml` with the directory: the scripts are in `scripts/`, but `platformCommand` points to
   `bin/audit.sh` and the install hook to `hooks/install-rules.sh`.
3. Fix `plugin.yaml`:
   ```yaml
   runtimeConfig:
     platformCommand:
       - command: "${HELM_PLUGIN_DIR}/scripts/audit.sh"
     platformHooks:
       install:
         - command: "${HELM_PLUGIN_DIR}/scripts/install-rules.sh"
   ```
4. The hook only runs at install time, and the command needs the `rules.env` file the hook creates. Reinstall:
   ```bash
   helm plugin uninstall hm-audit
   helm plugin install ./hm-audit
   ```
5. `helm hm-audit checkout -n helmissions` now prints `containers=2 missing_limits=1` and names
   `checkout/metrics-exporter`.
