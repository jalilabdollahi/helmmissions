# HelmMissions Curriculum

133 levels, 10 modules. Each entry is the contract for one level: **what is broken**, **what the player
must achieve**, and **what the validator must prove** (plus the most tempting wrong fix it must reject).
Level authors may refine details (names, values, wording) but must keep the core bug and lesson, and
must not let a level drift into another level's lesson. Release/app names below are suggestions;
vary them so no two levels feel alike. All levels follow [LEVEL_SPEC.md](LEVEL_SPEC.md).

Format: `L<n> slug — Title (XP · difficulty · time)`

---

## Module 1 — Helm Basics (beginner)

**L1 chart-version-missing — The Nameless Chart (100 · beginner · 5m)** ✅ *reference level, done*
Chart.yaml of `webapp` has `appVersion` but no chart `version` → "chart.metadata.version is required".
Player adds a SemVer version and installs release `webapp`. Validate: lint passes, version 0.1.0,
release deployed, pods ready. Reject: `helm template | kubectl apply`.

**L2 invalid-release-name — Name Rejected (100 · beginner · 5m)**
Workspace has `deploy.sh` running `helm install Shop_Frontend ./storefront` → "invalid release name".
Player makes the script work (DNS-1123 name `shop-frontend`) and runs it. Validate: release
`shop-frontend` deployed from the storefront chart and pods ready; the release name used in deploy.sh
is valid DNS-1123 and matches the deployed release.

**L3 image-tag-typo — Pull Backoff (100 · beginner · 10m)**
Release `ledger-api` installed; pods in ImagePullBackOff because values has `tag: 1.27-alpien`.
Player fixes values.yaml and upgrades. Validate: pods ready with `nginx:1.27-alpine`, values.yaml in
workspace has the right tag, revision ≥ 2. Reject: `kubectl set image` hotfix (release values still bad).

**L4 templates-dir-misnamed — The Empty Release (100 · beginner · 5m)**
Chart keeps manifests in `template/` (singular). `helm install` "succeeds" but creates no resources.
Player renames to `templates/` and upgrades. Validate: release manifest contains Deployment+Service,
pods ready. Reject: applying the YAML with kubectl.

**L5 required-value-missing — Required Means Required (150 · beginner · 10m)**
Chart uses `required "ingressHost is required"`; install fails. Player sets the value **in a values file
in the workspace** (`values-staging.yaml`, chart defaults stay generic) and installs release `docs-site`.
Validate: release deployed, user-supplied values contain the host, Ingress host matches.

**L6 chart-yml-misnamed — Chart.yml Is Not Chart.yaml (100 · beginner · 5m)**
Chart metadata file is named `Chart.yml` → "Chart.yaml file is missing". Rename, install `status-page`.
Validate: workspace chart has Chart.yaml (no Chart.yml), release deployed.

**L7 service-targetport-mismatch — Connection Refused (150 · beginner · 10m)**
`inventory` Service has endpoints but targetPort 8080 while nginx listens on 80 → requests refused.
Player fixes the value and upgrades. Validate: HTTP request to the Service from inside the cluster
returns 200; values fixed; revision ≥ 2. Reject: `kubectl patch svc`.

**L8 namespace-missing — Nowhere To Land (100 · beginner · 5m)**
Team wants release `metrics-proxy` in namespace `helmissions-staging`, which doesn't exist → "namespaces
not found". Player installs with `--create-namespace` (or creates it). Validate: release deployed in
`helmissions-staging` (not in `helmissions`).

**L9 name-in-use — Cannot Re-use a Name (150 · beginner · 10m)**
Release `orders` (chart 0.1.0) is deployed. The new chart 0.2.0 in the workspace must be rolled out;
`helm install orders` fails "cannot re-use a name". Player upgrades. Validate: release `orders` running
chart 0.2.0, history still contains revision 1 (no uninstall), pods ready. Reject: uninstall+install.

**L10 set-key-case — The Silent --set (150 · beginner · 10m)**
A colleague ran `helm upgrade billing ... --set replicacount=4`; still 1 replica. Player scales to 4
using the correct key. Validate: Deployment has 4 replicas (ready), user-supplied values have
`replicaCount: 4` and no stray `replicacount`.

**L11 get-values-forensics — The Mystery Override (150 · beginner · 10m)**
Release `weather-widget` points at the wrong API URL. Chart files are correct; someone deployed it with
`--set config.apiUrl=http://localhost:9999`. Player discovers it with `helm get values` and redeploys
without the override. Validate: no user-supplied apiUrl, ConfigMap has the chart default URL.

**L12 packaged-chart-show-values — Read The Label (150 · beginner · 10m)**
Only a packaged vendor chart `vendor/node-probe-0.4.2.tgz` is provided (no source). Player must find the
right key with `helm show values`/`show readme` and install release `node-probe` with the Service
port set to 9100 via a values file `probe-values.yaml`. Validate: release from that chart version,
Service port 9100, values file exists and is the source of the override.

**L13 non-manifest-in-templates — Not Every File Is A Manifest (100 · beginner · 10m)**
`templates/usage-notes.yaml` contains plain prose → "error converting YAML to JSON". Player moves/renames
it (e.g. to NOTES.txt or out of templates/) and installs `helpdesk`. Validate: release deployed, no
non-manifest yaml in templates, rendered manifests all have apiVersion/kind.

**L14 helm-lint-errors — Lint Before You Ship (150 · beginner · 10m)**
CI requires `helm lint --strict` to pass for chart `newsletter`; it has several distinct issues (e.g.
invalid SemVer version, chart name with uppercase/mismatch, values referenced but missing → warning,
missing icon is INFO only). Player fixes all. Validate: `helm lint --strict` passes, chart still renders
the same resources, release `newsletter` installed.

**L15 package-with-helmignore — Ship A Clean Package (150 · beginner · 15m)**
Player must package chart `reports` version 1.1.0 into `dist/` and install from the .tgz. The chart dir
contains `secrets.local.env`, `*.bak` and a `tmp/` folder that must NOT be in the package (.helmignore
missing/incomplete). Validate: `dist/reports-1.1.0.tgz` exists without the junk files, release
`reports` runs chart version 1.1.0.

---

## Module 2 — Values & Overrides (beginner → intermediate)

**L1 set-file-config — A Path Is Not A File (150 · beginner · 10m)**
Nginx config must be injected from `site.conf` into release `landing`. Colleague used
`--set siteConfig=./site.conf` so the ConfigMap literally contains "./site.conf". Player uses
`--set-file` (or a values file). Validate: ConfigMap data equals site.conf content, pods ready.

**L2 bool-string-truthy — "false" Is True (150 · beginner · 10m)**
`ingress.enabled: "false"` (string) → Ingress still rendered. Player fixes the type. Validate: no
Ingress in release manifest, values.yaml has boolean false. Reject: deleting the Ingress with kubectl.

**L3 nil-nested-map — nil pointer evaluating (200 · intermediate · 15m)**
Template reads `.Values.cache.redis.host`; values for an env lacks `cache:` → "nil pointer evaluating
interface {}.redis". Player makes the template safe (`dig`/`with`/defaults) so the chart renders both
with and without the cache block. Validate: `helm template` passes with values lacking `cache`, still
renders host when provided; release `profile-svc` deployed.

**L4 set-escaped-dots — Dots In Keys (200 · intermediate · 10m)**
Pods need annotation `prometheus.io/scrape: "true"` via `podAnnotations`. Colleague's
`--set podAnnotations.prometheus.io/scrape=true` created nested junk. Player escapes dots (or uses a
values file). Validate: pod template annotation key exactly `prometheus.io/scrape`, value "true".

**L5 string-instead-of-list — range can't iterate (150 · beginner · 10m)**
`allowedOrigins: "https://shop.example"` (string) but template ranges over it → render error. Player
makes it a list. Validate: rendered ConfigMap has each origin, release `cors-gateway` deployed.

**L6 set-list-syntax — Commas In --set (200 · intermediate · 10m)**
Two DNS search domains must be passed with `--set`; colleague's `--set dnsSearch=a.svc,b.svc` failed.
Player uses `{a,b}` syntax or index syntax. Validate: pod dnsConfig.searches has both entries.

**L7 values-file-order — Last One Wins (150 · beginner · 10m)**
`deploy.sh` runs `-f values-prod.yaml -f values-base.yaml` so base overrides prod (1 replica, debug
logging in prod). Player fixes order and redeploys `checkout` into `helmissions-prod`. Validate:
3 replicas, LOG_LEVEL=warn, deploy.sh order fixed.

**L8 missing-default — <no value> In Production (150 · beginner · 10m)**
Template renders `timeout: {{ .Values.http.timeout }}`; value absent → ConfigMap shows `<no value>`.
Player adds a sane default in the template (`default 30`) — chart must work with key absent. Validate:
rendered value 30 when unset, override still works, release `fetcher` updated.

**L9 tab-indentation — Invisible Tabs (150 · beginner · 10m)**
values.yaml contains TAB indentation → "found character that cannot start any token". Player fixes.
Validate: values.yaml parses, no tabs, release `audit-log` deployed with the intended values.

**L10 reuse-values-new-default — --reuse-values Ate My Default (250 · intermediate · 15m)**
Chart 2.0 adds `metrics.port` with a default; CI upgrades with `--reuse-values` → nil error / missing
value. Player upgrades with `--reset-then-reuse-values` (or re-supplies values). Validate: release on
chart 2.0, metrics port rendered, earlier user override (`replicaCount: 2`) preserved.

**L11 hash-in-unquoted-value — The # Ate My Password (200 · intermediate · 10m)**
`db.password: s3cret#2024` unquoted → YAML comment truncates to `s3cret`. App auth check (init
container comparing to expected) fails. Player quotes it. Validate: Secret decodes to full value, pods
ready.

**L12 memory-units — 256 Bytes Of RAM (150 · beginner · 10m)**
`resources.limits.memory: 256` (bytes) → container cannot start. Player fixes to `256Mi`. Validate:
pods running, limit 256Mi, values fixed.

**L13 large-int-scientific — 1.0e+06 (200 · intermediate · 15m)**
`maxUploadBytes: 1048576` renders as `1.048576e+06` in an env var/ConfigMap → app rejects. Player fixes
in the template (`int`/`toString` or quoting the value). Validate: rendered value exactly "1048576",
works for override 5242880 too.

**L14 schema-enum — The Schema Says No (200 · intermediate · 10m)**
values.schema.json enforces `logLevel` enum and `replicas >= 1`; values has `logLevel: WARN` and
`replicas: 0` → schema validation error. Player fixes the VALUES (schema is policy, must stay
unchanged). Validate: schema checksum unchanged, release `search-api` deployed.

**L15 set-string-trailing-zero — 1.10 Became 1.1 (200 · intermediate · 10m)**
`--set appVersionLabel=1.10` turns into float `1.1` in a label → wrong version shown. Player uses
`--set-string`. Validate: pod label `app.version: "1.10"`.

---

## Module 3 — Template Debugging (intermediate → advanced)

**L1 unclosed-action — Unclosed Action (200 · intermediate · 5m)** `{{ .Values.app.name }` → parse error.
**L2 toyaml-indent — Mis-indented Resources (250 · intermediate · 10m)** `toYaml .Values.resources | indent 6`
on wrong level → resources land under the wrong key / invalid. Validate: container has limits/requests.
**L3 values-path-typo — Empty Image (200 · intermediate · 10m)** `.Values.image.respository` → image
`:1.27-alpine` → InvalidImageName.
**L4 root-context-in-with — Lost In with (250 · intermediate · 10m)** `.Release.Name` inside
`with .Values.labels` → "can't evaluate field Release". Fix with `$`.
**L5 undefined-function — function "uppercase" not defined (200 · intermediate · 5m)** Fix to `upper`.
**L6 default-arg-order — Default Always Wins (250 · intermediate · 10m)** `default .Values.image.tag
"1.27-alpine"` (args swapped) → pinned tag ignored. Validate: pinned tag `1.27-alpine` vs override
`does-not-exist` respected in render.
**L7 include-name-mismatch — no template named (250 · intermediate · 10m)** include `"shop.labels"` vs
define `"storefront.labels"`.
**L8 indent-vs-nindent — Misaligned Labels (200 · intermediate · 10m)** `labels: {{ include ... | indent 4 }}`
on the same line → first label misaligned → YAML error. Fix with nindent.
**L9 capabilities-api-check — Wrong Ingress API (300 · advanced · 15m)** Template picks
`networking.k8s.io/v1beta1` because the `.Capabilities.APIVersions.Has` check is inverted/misspelled →
"no matches for kind". Validate: renders v1 against the live cluster (`helm template --validate` or
install).
**L10 duplicate-port-names-range — Duplicate Port Names (250 · intermediate · 10m)** range over
`ports` list hardcodes `name: http` → API rejects duplicates. Use `.name`.
**L11 unquoted-env-number — Number In An Env Var (200 · intermediate · 10m)** `value: {{ .Values.port }}`
→ "cannot unmarshal number into ... EnvVar.value of type string". Quote it.
**L12 tpl-in-values — Literal Braces (300 · advanced · 15m)** values hold `"{{ .Release.Name }}-db"`;
template prints it literally. Use `tpl`. Validate: env DB_HOST = `<release>-db`.
**L13 printf-float-verb — %!d(float64=8080) (250 · intermediate · 10m)** `printf "%d"` on a float64
value. Fix with `%v`/`int`.
**L14 files-get-helmignore — The Vanishing Config File (300 · advanced · 15m)** `.Files.Get
"files/app.conf"` returns empty because `.helmignore` excludes `*.conf`. Validate: ConfigMap contains the
file content.
**L15 secret-not-base64 — illegal base64 data (200 · intermediate · 10m)** Secret `data:` holds a plain
value. Use `b64enc` (or stringData). Validate: decoded value correct.
**L16 dict-context-helper — Helper Needs A Dict (300 · advanced · 15m)** helper expects
`(dict "ctx" . "component" "worker")` but callers pass `.` → nil errors/empty names. Validate: both
components render distinct names.
**L17 over-chomped-whitespace — Lines Glued Together (250 · intermediate · 10m)** `{{-`/`-}}` chomps a
newline → `replicas: 2selector:` YAML error.
**L18 missing-doc-separator — The Disappearing Deployment (250 · intermediate · 10m)** two resources in
one file without `---` → only one is created / duplicate-key error. Validate: both exist.
**L19 selector-label-drift — No Endpoints (300 · advanced · 15m)** Service selector hand-written
(`app: payments`) while Deployment uses helper labels → 0 endpoints. Fix by using the shared
selectorLabels helper in both. Validate: endpoints > 0 and both templates use include.
**L20 lookup-stable-secret — The Password Changes Every Deploy (350 · advanced · 20m)** `randAlphaNum`
regenerates the DB password on every upgrade. Use `lookup` to keep the existing value. Validate:
validator upgrades twice; password unchanged.

---

## Module 4 — Release Management (intermediate → advanced)

**L1 failed-first-install — Born Failed (200 · intermediate · 10m)** First install of `invoice-api`
failed (API rejected an invalid field); release is `failed`. Player fixes the chart and gets it
`deployed` (upgrade or uninstall+install both fine). Validate: latest revision deployed, pods ready.
**L2 failed-upgrade-fix-forward — Fix Forward (250 · intermediate · 10m)** rev1 deployed, rev2 failed
(bad probe type). Player fixes chart and upgrades → rev3 deployed with the NEW feature of rev2 present.
Reject: rollback (feature lost).
**L3 wait-readiness-timeout — Timed Out Waiting (250 · intermediate · 15m)** `helm upgrade --wait
--timeout 45s` fails: readinessProbe path `/healthz` 404s on nginx. Fix probe, upgrade with --wait.
**L4 auto-rollback-diagnosis — The Upgrade That Undid Itself (300 · advanced · 15m)**
`--rollback-on-failure` (v4) / `--atomic` (v3) upgrade failed and rolled back; player reads history
descriptions to find why (immutable/invalid field), fixes, upgrades. Validate: newest revision deployed
contains the intended change.
**L5 ci-upgrade-install — First Deploy Breaks CI (200 · intermediate · 10m)** `ci/deploy.sh` uses `helm
upgrade` → "has no deployed releases" on first deploy. Fix script (`--install`), run it. Validator
re-runs the script against a fresh namespace `helmissions-ci` to prove it works on first deploy.
**L6 adopt-existing-resource — Invalid Ownership Metadata (300 · advanced · 15m)** ConfigMap
created by kubectl blocks install. Adopt it (annotations/labels or `--take-ownership`) — don't lose
its data? (Chart's data must win.) Validate: release deployed, ConfigMap owned by release.
Alt fix: delete it first.
**L7 immutable-selector — field is immutable (250 · intermediate · 15m)** chart 1.1 changed
Deployment selector labels → upgrade fails. Player keeps the selector stable while keeping the new
pod label. Validate: upgrade succeeded, selector unchanged, new label on pods. Reject: uninstall.
**L8 revision-forensics — Bring Back Revision 2's Setting (250 · intermediate · 15m)** 5 revisions;
`FEATURE_SEARCH` was disabled in rev 3 by mistake; later revisions added good changes. Restore the
setting WITHOUT rollback. Validate: latest is an upgrade, rev 4/5 changes present, setting restored.
**L9 kept-resource-blocks-rename — resource-policy: keep (300 · advanced · 15m)** Release `shop` was
uninstalled; its PVC/Secret had `helm.sh/resource-policy: keep`; installing as `storefront` fails on
ownership. Player resolves (delete or re-annotate kept object). Validate: `storefront` deployed and
owns the object; data in Secret preserved if re-annotated (either accepted).
**L10 uninstall-keep-history-restore — Undo An Uninstall (200 · intermediate · 10m)** Release uninstalled
with `--keep-history`. Restore it with `helm rollback`. Validate: status deployed, history continued
(rollback description).
**L11 release-name-too-long — Must Be No More Than 63 Characters (250 · intermediate · 15m)** Release
`customer-notification-dispatcher-production-eu` makes resource names > 63 chars (helper doesn't
trunc). Fix the fullname helper. Validate: release with that exact name deployed.
**L12 stuck-pending-upgrade — Another Operation In Progress (300 · advanced · 15m)** Release stuck in
`pending-upgrade` (helm process killed). Recover (rollback to last deployed, then upgrade if needed).
Validate: deployed, not pending.
**L13 crd-ordering — no matches for kind (300 · advanced · 15m)** CRD and a CR in `templates/` →
first install fails. Move CRD to `crds/`. Validate: CRD + CR exist, release deployed.
**L14 helm-test-fails — Red Test Suite (250 · intermediate · 10m)** `helm test` pod targets wrong
service name/port. Fix the test, run `helm test`. Validate: last test run succeeded.
**L15 notes-render-error — Broken NOTES.txt (150 · beginner · 10m)** NOTES.txt references a nil
value → install fails with NOTES error. Fix NOTES so it renders. Validate: deployed, `helm get notes`
shows the URL.

---

## Module 5 — Rollbacks & Recovery (intermediate → advanced)

**L1 simple-rollback — Roll It Back (200 · intermediate · 5m)** rev2 broke `quotes-api` (bad image).
Roll back. Validate: latest is "Rollback to 1", pods ready. Reject: upgrade.
**L2 hotfix-drift — The Hotfix That Vanished (250 · intermediate · 15m)** on-call fixed prod with
`kubectl set env`; the next `helm upgrade` silently reverted it (outage again). Make it durable in
values and upgrade. Validate: env in values + live, revision bumped.
**L3 bisect-history — Find The Last Good Revision (300 · advanced · 15m)** 6 revisions, several bad in
different ways; the newest good one is rev 4 (rev 1 lacks a required feature). Roll back to it.
Validate: rollback to 4.
**L4 deleted-resource-recovery — Somebody Deleted The Service (250 · intermediate · 10m)** Service
removed with kubectl. Restore it through Helm (upgrade/rollback re-creates). Validate: Service exists
with Helm ownership, endpoints > 0.
**L5 config-checksum-restart — Rolled Back But Still Broken (300 · advanced · 15m)** rollback restored
the ConfigMap but pods keep old config (no restart). Add `checksum/config` pod annotation so config
changes roll pods; upgrade. Validate: annotation present, pod sees current config.
**L6 history-max-pruned — The Good Revision Is Gone (250 · intermediate · 15m)** `--history-max 3`
pruned the last good revision; rollback impossible. Fix forward. Validate: deployed, good values.
**L7 force-replace-job — Immutable Job Template (300 · advanced · 15m)** upgrade changes a Job's pod
template → immutable error. Use `--force-replace` (v4) / `--force` (v3), or delete the Job. Validate:
new Job spec live, release deployed.
**L8 storage-driver-configmap — The Invisible Release (300 · advanced · 15m)** CI stored the release
with `HELM_DRIVER=configmap`; `helm list` shows nothing. Find and roll back the bad revision using the
right driver. Validate: release (configmap driver) latest is rollback, pods healthy.
**L9 crds-not-upgraded — The CRD That Never Updated (350 · advanced · 20m)** chart 2.0 updated
`crds/` (new field) but `helm upgrade` never touches crds/ → CR rejected / field pruned. Apply the CRD
update, then upgrade. Validate: CRD has the field, CR has it, release deployed.
**L10 rollback-hook-blocks — Pre-rollback Hook Says No (300 · advanced · 15m)** a pre-rollback hook
fails and blocks recovery. Use `--no-hooks` (or fix hook via upgrade). Validate: rolled back, healthy.
**L11 statefulset-vct-forbidden — Forbidden: StatefulSet Spec (350 · advanced · 20m)** upgrade
changed volumeClaimTemplates → forbidden. Revert that part, keep the other change. Validate: deployed,
VCT unchanged, other change applied.
**L12 blue-green-switchback — Switch Back To Blue (250 · intermediate · 10m)** chart runs blue+green;
`activeColor: green` but green is broken. Switch traffic back to blue via values/upgrade (keep green
deployed for debugging). Validate: Service selects blue, endpoints ready.
**L13 immutable-configmap — Immutable ConfigMap (300 · advanced · 15m)** ConfigMap `immutable: true`;
upgrade changing data fails. Make the name content-hashed so new config creates a new map. Validate:
upgrade with changed data succeeds.
**L14 hpa-replicas-reset — Every Deploy Scales To 1 (300 · advanced · 15m)** HPA manages replicas but
chart sets `replicas:` → each upgrade resets to 1. Omit replicas when autoscaling enabled. Validate:
rendered Deployment lacks replicas when HPA on, release upgraded.
**L15 production-incident — Incident: Checkout Is Down (400 · advanced · 25m)** Combined: bad upgrade
+ drift + the obvious rollback target is also bad. Restore service with the right revision and make the
fix durable. Validate: healthy, correct revision behavior, chart values corrected.

---

## Module 6 — Chart Dependencies (advanced)

**L1 missing-charts-dir — Missing In charts/ (200 · intermediate · 10m)** file:// dependency declared,
charts/ empty. `helm dependency build/update`.
**L2 lock-out-of-sync — Chart.lock Out Of Sync (250 · intermediate · 10m)** dependency version bumped in
Chart.yaml, Chart.lock stale → build refuses. `helm dependency update`. Validate: lock matches, deployed.
**L3 version-range-no-match — No Matching Version (250 · intermediate · 15m)** local HTTP repo serves
`redis-lite` 1.2.x only; constraint `^2.0.0`. Fix range.
**L4 alias-duplicate — Same Chart Twice (300 · advanced · 15m)** need two instances of the same
subchart (primary/replica) → use aliases with distinct values.
**L5 subchart-values-scope — Values Not Reaching The Subchart (250 · intermediate · 10m)** values for
subchart not nested under its name/alias.
**L6 global-values — One Setting For All Subcharts (300 · advanced · 15m)** subcharts read
`.Values.global.region`; parent sets top-level `region`.
**L7 condition-path — Disabled But Still Deployed (250 · intermediate · 10m)** `condition: cache.enable`
vs values `cache.enabled: false`.
**L8 tags-group — Toggle A Group (300 · advanced · 15m)** monitoring subcharts must be toggled together
via `tags`; tags misconfigured.
**L9 repo-not-added — no repository definition (250 · intermediate · 10m)** `repository: "@hm-stable"`
alias but repo not added → add `hm-stable` (local HTTP repo) and update deps.
**L10 oci-dependency-url — OCI Reference Format (300 · advanced · 15m)** dependency repository
includes the chart name (`oci://localhost:5001/x/charts/cache`) → fix to the registry path.
**L11 import-values — Parent Needs Child's Value (350 · advanced · 20m)** parent template uses
`.Values.dbPort` that should come from the child via `import-values`/exports; mis-specified.
**L12 legacy-requirements-yaml — The Ignored requirements.yaml (300 · advanced · 15m)** chart upgraded
to apiVersion v2 but dependencies still in `requirements.yaml` → silently ignored. Move to Chart.yaml.
**L13 subchart-hook-blocks — A Subchart's Hook Blocks Everything (350 · advanced · 20m)** subchart
pre-install migration hook fails because parent didn't pass its DB host → whole install fails. Fix by
passing the subchart value (not `--no-hooks`). Validate: hook ran successfully.

---

## Module 7 — Helm Hooks (advanced)

**L1 pre-install-hook-fails — Blocked By A Hook (250 · intermediate · 10m)** pre-install Job's command
checks a wrong env var/path → install fails. Fix hook.
**L2 post-install-retry — Too Impatient (300 · advanced · 15m)** post-install smoke test with
`backoffLimit: 0` runs before pods are ready → release failed. Make it retry/wait properly.
**L3 hook-already-exists — Hook Job Already Exists (250 · intermediate · 10m)** no
`hook-delete-policy` → second upgrade fails ("already exists"). Add `before-hook-creation`.
**L4 hook-weight-order — Migrations Before The Database (300 · advanced · 15m)** two pre-install hooks
run in the wrong order (weights). Fix weights.
**L5 wrong-hook-phase — The Migration Ran Too Late (300 · advanced · 15m)** migration is a
`post-upgrade` hook but must run `pre-upgrade`. Validate: annotation + ordering evidence.
**L6 post-delete-cleanup — Uninstall Leaves A Mess (300 · advanced · 15m)** uninstall leaves a PVC
created by a Job. Add a post-delete hook to clean it. Validator does install+uninstall in
`helmissions-verify`.
**L7 hook-deletes-needed-config — The Config That Hooked Itself Away (300 · advanced · 15m)** a
ConfigMap the app needs is annotated as a hook with `hook-succeeded` → deleted → pods fail. Remove hook
annotations so it's a normal release resource.
**L8 test-annotation-typo — "No Tests Found" (250 · intermediate · 10m)** test pod annotated
`helm.sh/hook: tests` → runs at install, `helm test` finds none. Fix annotation, run test.
**L9 hook-rbac — Forbidden Inside The Hook (350 · advanced · 20m)** hook Job queries the API (lists
ConfigMaps) without RBAC → forbidden. Add SA+Role+RoleBinding as hooks with lower weight.
**L10 hook-before-resources — The Secret Isn't There Yet (350 · advanced · 20m)** pre-install hook
needs a Secret that is a normal release resource (created after hooks). Make the Secret a
pre-install hook with lower weight (or restructure).

---

## Module 8 — Security & Linting (advanced)

**L1 secret-in-values — Password In Git (250 · intermediate · 15m)** chart reads DB password from
values; values.yaml holds plaintext. Use `existingSecret` (create Secret via kubectl) and remove the
password from values. Validate: no password in workspace values, pod env from secretKeyRef.
**L2 least-privilege-role — 403 From The API (300 · advanced · 15m)** app (curl image with SA token)
needs `list configmaps`; Role grants pods only. Grant exactly that — no wildcards. Validate: access
works (`kubectl auth can-i --as`), Role has no `*`.
**L3 network-policy-selector — Policy Blocks The Frontend (300 · advanced · 15m)** NetworkPolicy
`from.podSelector` label mismatch blocks frontend → backend. Fix selector (keep default-deny). Validate:
frontend reaches backend, other pods blocked (or policy semantics checked if CNI lacks enforcement).
**L4 run-as-non-root — container has runAsNonRoot and image will run as root (250 · intermediate ·
10m)** keep runAsNonRoot; switch to unprivileged image/port. Validate: ready, runAsNonRoot true.
**L5 private-registry-pull-secret — Unauthorized Pull (300 · advanced · 15m)** image in a private
registry (`localhost:5002`, auth) → ImagePullBackOff. Create docker-registry Secret, wire
`imagePullSecrets` via values.
**L6 ci-policy-gate — The Policy Gate (300 · advanced · 15m)** `ci/policy.sh` (helm template + jq)
rejects: `latest` tags, missing limits, missing probes. Fix chart until the gate passes, deploy.
**L7 removed-apis — Removed APIs (300 · advanced · 15m)** chart uses `policy/v1beta1`
PodDisruptionBudget and `autoscaling/v2beta2` HPA → "no matches for kind". Update APIs.
**L8 resource-quota-requests — Quota Says No (300 · advanced · 15m)** namespace ResourceQuota requires
requests/limits → ReplicaSet can't create pods (events). Set resources in values.
**L9 pod-security-restricted — Restricted Pod Security (350 · advanced · 20m)** namespace enforces PSA
`restricted` → pods rejected. Add allowPrivilegeEscalation false, drop ALL, seccomp RuntimeDefault,
runAsNonRoot. Keep enforcement.
**L10 provenance-signing — Verify Before You Trust (350 · advanced · 20m)** package and sign the chart
with the provided GPG key, produce `.prov`, verify with `helm verify`, install with `--verify`.

---

## Module 9 — Advanced Patterns (expert)

**L1 library-chart-extract — DRY With A Library (350 · advanced · 20m)** two app charts duplicate
helpers that drifted. Create a library chart, depend on it, use its templates. Validate: both render
identical label sets from the library, library `type: library`.
**L2 library-chart-misdeclared — library charts are not installable (300 · advanced · 15m)** shared
chart declared wrongly (type/templates) causing duplicate resources or install error. Fix type and
file naming (`_` prefix).
**L3 oci-push-install — Ship Via OCI (350 · advanced · 15m)** package and push chart to
`localhost:5001`, install release from `oci://` with `--version`. Broken: push command uses wrong ref.
**L4 post-renderer — Patch After Render (400 · expert · 25m)** must add a label/sidecar the chart
can't express via a post-renderer (Helm 4: plugin of type postrenderer/v1; Helm 3: executable) using
`kubectl kustomize`. Broken plugin/script provided.
**L5 local-plugin — Plugin Won't Load (300 · advanced · 15m)** local plugin `hm-audit` has a broken
plugin.yaml / command path. Fix and install.
**L6 kustomize-helm-inflation — Kustomize Inflates Helm (400 · expert · 20m)** `kubectl kustomize
--enable-helm` with `helmCharts` entry pointing to wrong chartHome/valuesFile. Fix and apply.
**L7 repo-index-stale — Stale index.yaml (350 · advanced · 15m)** local chart repo index lacks the new
version; regenerate with `helm repo index --merge`, update repo, install 1.3.0.
**L8 schema-strict-typos — Catch Typos With A Schema (350 · advanced · 20m)** add a values schema with
`additionalProperties: false` so typo'd keys fail. Validator tests a typo → must fail; good → passes.
**L9 offline-render-api-versions — GitOps Render Lost The ServiceMonitor (400 · expert · 20m)**
`render.sh` uses `helm template` (no cluster) so Capabilities lacks the CRD → resource silently
dropped. Fix with `--api-versions`/`--kube-version`.
**L10 umbrella-five-services — Umbrella Down (450 · expert · 30m)** umbrella with 5 subcharts; one
template error + global registry value ignored by one subchart.

---

## Module 10 — Production War Games (expert)

**L1 multi-tier-failure — Three Tiers Down (450 · expert · 30m)** db hook fails, api env wrong,
frontend upstream wrong. Fix in dependency order.
**L2 registry-migration — Registry Moved (450 · expert · 25m)** images moved to `localhost:5001`;
three releases; one subchart ignores `global.imageRegistry`.
**L3 canary-split — The 50% Canary (400 · expert · 20m)** stable + canary releases behind one Service;
canary should be ~10% (1 of 10 pods) but is 50%; canary also missing the shared selector label.
**L4 cross-namespace-dns — Wrong Namespace DNS (400 · expert · 20m)** frontend in
`helmissions-web` calls backend in `helmissions-api` by short name.
**L5 prod-deployed-with-dev-values — Dev Values In Prod (450 · expert · 25m)** pipeline script deployed
dev values to prod namespace. Fix script/values selection and redeploy prod.
**L6 unschedulable-requests — Pending Forever (450 · expert · 25m)** requests exceed node capacity
(Insufficient cpu) across releases; right-size and roll out.
**L7 promotion-pipeline — Silent Pipeline Failure (450 · expert · 30m)** `pipeline.sh` promotes
dev→staging→prod, staging values missing, no `set -e` → prod deployed broken. Fix script + values.
**L8 removed-api-in-release-history — unable to build kubernetes objects from current release
manifest (500 · expert · 30m)** stored release manifest contains a removed API; upgrade fails. Patch the
release record (decode/patch/re-encode secret) like mapkubeapis.
**L9 cluster-scoped-name-collision — Two Teams, One ClusterRole (450 · expert · 25m)** two releases
in different namespaces create the same cluster-scoped name → ownership conflict. Make names
release-scoped.
**L10 final-incident — The Final Incident (600 · expert · 45m)** multi-failure finale: stuck release,
bad values across envs, failing hook, dependency mismatch.
