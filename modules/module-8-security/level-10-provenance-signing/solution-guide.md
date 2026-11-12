# Verify Before You Trust — Walkthrough

1. `./deploy.sh` packages the chart and then fails: `could not load provenance file dist/payments-gateway-1.0.0.tgz.prov`.
   The install asks for `--verify`, but nobody signed the package.
2. `keys/README.txt` names the signing key: user id `HelmMissions Release Signer`. Helm reads exported keyring
   files directly, no GnuPG agent is needed.
3. Sign while packaging (secret keyring!):
   ```bash
   helm package payments-gateway -d dist --sign --key 'HelmMissions Release Signer' --keyring keys/signer-secring.gpg
   ls dist/        # payments-gateway-1.0.0.tgz  payments-gateway-1.0.0.tgz.prov
   ```
4. Verify with the public keyring:
   ```bash
   helm verify dist/payments-gateway-1.0.0.tgz --keyring keys/signer-pubring.gpg
   # Signed by: HelmMissions Release Signer ... Chart Hash Verified: sha256:...
   ```
5. Install the package with verification: `helm upgrade --install payments-gateway dist/payments-gateway-1.0.0.tgz -n helmissions --verify --keyring keys/signer-pubring.gpg --wait`
   (or add `--sign --key ... --keyring keys/signer-secring.gpg` to the `helm package` line in `deploy.sh` and run it).
6. Run `check`.
