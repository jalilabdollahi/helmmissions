# INC-2291 - checkout is down (timeline so far)

- Mon 09:02  Release checkout rev 1 deployed, healthy since the migration.
- Fri 15:10  rev 2: payment provider switched to `legacy-gw` by the vendor-migration PR. Checkout fails.
- Fri 15:25  On-call forces the fallback circuit breaker with `kubectl set env deployment/checkout FORCE_FALLBACK=1`.
- Fri 16:55  rev 3: "tune payment client" PR deployed from values-prod.yaml. Checkout still down.
- Now        Marketing campaign is live. Nobody trusts rev 2. Fix it, and make sure the next pipeline run
             does not bring it back.
