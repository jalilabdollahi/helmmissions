# Incident: Checkout Is Down - Walkthrough

1. Read `INCIDENT.md` and the symptom:
   ```bash
   curl via a pod: http://checkout/checkout.txt   # FAILING - payment timeout 300ms is too short
   helm history checkout -n helmissions            # 3 revisions
   ```
2. Inspect the revisions:
   ```bash
   helm get values checkout -n helmissions --revision 1    # defaults: stripe-v2, 3000ms
   helm get values checkout -n helmissions --revision 2    # payment.provider=legacy-gw
   helm get values checkout -n helmissions --revision 3    # timeoutMs: 300
   ```
   Revision 2 (the obvious rollback target) is broken, too. Revision 1 is the last good one.
3. Look for drift between the release and the cluster:
   ```bash
   helm get manifest checkout -n helmissions | grep -A1 'name: '    # no FORCE_FALLBACK
   kubectl get deploy checkout -n helmissions -o jsonpath='{.spec.template.spec.containers[0].env}'   # has FORCE_FALLBACK=1
   ```
4. Restore service:
   ```bash
   helm rollback checkout 1 -n helmissions --wait
   kubectl set env deployment/checkout FORCE_FALLBACK- -n helmissions    # rollback never removes manual additions
   ```
5. Make it durable: in `values-prod.yaml` set `timeoutMs: 3000` (the PR's "tuning" was the bug) and deploy through the
   pipeline:
   ```bash
   bash ci/deploy.sh
   ```
6. Verify `checkout: ok`, then run `check`.
   (Fixing forward - correct values-prod.yaml, remove the hotfix env, run the pipeline - is equally valid.)
