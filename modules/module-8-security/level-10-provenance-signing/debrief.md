# Verify Before You Trust

## What broke
`helm install --verify` demands a provenance file (`<chart>.tgz.prov`) next to the package and checks its PGP signature and
the SHA-256 of the archive. The release script packaged the chart but never signed it, so there was nothing to verify and
Helm stopped before touching the cluster. That is the control working: an unsigned package is, by definition, an
artifact nobody vouched for.

## Why Helm behaves this way
A chart is a tarball that anyone with write access to a repository or registry can replace. Provenance binds a
specific archive hash to a key: `helm package --sign` writes a clear-signed document that contains the chart metadata and
the archive digest; `helm verify` (and `--verify` on install/upgrade/pull) checks the signature with a public keyring and
recomputes the digest. Signing needs the secret keyring, verification only the public one. Helm reads keyrings as files
(`--keyring`), so a legacy-format export (`gpg --export-secret-keys > secring.gpg`) works even without the gpg agent; Helm 4
still uses the same provenance format as Helm 3.

## The fix
Package with `--sign --key <uid> --keyring <secret keyring>`, run `helm verify` with the public keyring, then install the signed
package with `--verify`. Order matters: signing after the install proves nothing about what was deployed.

## In real life
Supply-chain attacks target the artifact between build and deploy: a compromised registry account, a mutable tag, a
hand-edited tarball. Provenance gives auditors (PCI, SOC 2) a verifiable chain from the release engineer's key to the
cluster. Teams stumble on key handling: the private key lives on a laptop or in CI variables without a passphrase, the
public keyring on the consumer side is wrong or stale, or a pipeline "temporarily" drops `--verify` after the first
failure and never puts it back. Sigstore/cosign signing of OCI charts is the modern alternative, but the principle is the same.

## Commands worth remembering
- `helm package CHART --sign --key NAME --keyring SECRING`
- `helm verify CHART.tgz --keyring PUBRING`
- `helm install|upgrade|pull ... --verify --keyring PUBRING`
- `gpg --export-secret-keys NAME > secring.gpg` / `gpg --export NAME > pubring.gpg`

## Common mistakes
- Passing the public keyring to `helm package --sign` (it needs the secret one) or the secret one to `--verify`.
- Removing `--verify` from the pipeline instead of producing the `.prov` file.
- Re-packaging after signing: any byte change in the `.tgz` invalidates the `.prov`.
- Verifying with the same key store that produced the signature in CI — consumers need an independently trusted public key.

## Helm 3 vs Helm 4
Both use the same provenance files and keyring formats, and both read binary keyring files given with `--keyring`.
On a machine whose GnuPG uses the newer `pubring.kbx` format, Helm 4's default keyring path is `~/.gnupg/pubring.kbx` (Helm 3 used `pubring.gpg`);
passing explicit exported keyrings (as in this level) avoids format surprises.
