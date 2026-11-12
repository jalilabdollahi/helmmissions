# Undo An Uninstall — Walkthrough

1. Find the release:
   ```bash
   helm list -n helmissions                 # empty
   helm list -n helmissions --uninstalled   # loyalty-points  REVISION 2  STATUS uninstalled
   helm history loyalty-points -n helmissions
   # 1 superseded   Install complete
   # 2 uninstalled  Uninstallation complete
   ```
2. Revision 2 is the one that was live (chart 1.1.0, replicas 2, gold threshold 500):
   ```bash
   helm get values loyalty-points -n helmissions --revision 2
   ```
   A plain `helm rollback loyalty-points` (no number) would pick revision 1, the *previous* one, and bring back the old chart.
3. Restore revision 2:
   ```bash
   helm rollback loyalty-points 2 -n helmissions --wait
   helm history loyalty-points -n helmissions     # 3 deployed  Rollback to 2
   ```
4. Verify pods and Service, then run `check`.
