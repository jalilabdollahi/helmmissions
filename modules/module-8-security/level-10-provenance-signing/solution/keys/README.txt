Release signing keys (exported from GnuPG as binary keyrings, as Helm expects them)

  signer-secring.gpg   secret key  — "HelmMissions Release Signer <signer@helmissions.local>", no passphrase
  signer-pubring.gpg   public key  — what consumers use to verify

Helm reads these files directly (--keyring PATH); it does not need gpg or the gpg-agent for them.
