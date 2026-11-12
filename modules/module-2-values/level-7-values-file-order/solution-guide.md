# Last One Wins - Walkthrough

1. Compare reality with intent:
   ```bash
   helm get values checkout -n helmissions-prod --all | head
   # replicaCount: 1, logLevel: debug
   cat values-prod.yaml values-base.yaml
   ```
2. In `deploy.sh` the flags are `-f values-prod.yaml -f values-base.yaml`. Helm applies value
   sources in order: chart `values.yaml` < each `-f` left to right < `--set`. Base is applied last,
   so it overwrites prod.
3. Fix the order in `deploy.sh`:
   ```bash
   -f values-base.yaml \
   -f values-prod.yaml \
   ```
4. Redeploy and check: `./deploy.sh`, then
   ```bash
   kubectl get deploy checkout -n helmissions-prod
   helm get values checkout -n helmissions-prod --all | grep -E 'replicaCount|logLevel|region'
   ```
5. Run `check`.
