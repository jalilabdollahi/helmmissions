# Stale Index — Walkthrough

1. Reproduce:
   ```bash
   helm repo update hm-tides
   helm search repo hm-tides/tide-tracker --versions      # 1.2.0 and 1.1.0 only
   ls repo                                                # tide-tracker-1.3.0.tgz is there, index.yaml does not know it
   ```
2. A repository is a folder + `index.yaml`. Helm builds the index from the tarballs it finds at the top level of the
   folder. 1.1.0 was retired to `archive/legacy/`, which `helm repo index` does not scan — a plain regeneration would
   drop it, and the regional cluster pinned to 1.1.0 would break.
3. Regenerate with `--merge` so existing entries are kept:
   ```bash
   helm repo index repo --url http://localhost:8879/m9-repo-index-stale --merge repo/index.yaml
   grep -E 'version:|urls' -A1 repo/index.yaml
   ```
4. Refresh the local cache and roll out:
   ```bash
   helm repo update hm-tides
   helm search repo hm-tides/tide-tracker --versions      # 1.3.0, 1.2.0, 1.1.0
   helm upgrade tide-tracker hm-tides/tide-tracker --version 1.3.0 -n helmissions --wait
   ```
5. Verify `helm pull hm-tides/tide-tracker --version 1.1.0` still works.
