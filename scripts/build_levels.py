#!/usr/bin/env python3
"""Generate HelmMissions level directories from PLAN.md."""

from __future__ import annotations

import json
import re
import shutil
import textwrap
from datetime import datetime, timezone
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
PLAN_PATH = ROOT / "PLAN.md"
MODULES_DIR = ROOT / "modules"
LEVELS_JSON = ROOT / "levels.json"
NS = "helmissions"
RELEASE = "helmissions-app"

MODULE_ORDER = {
    1: "module-1-basics",
    2: "module-2-values",
    3: "module-3-templates",
    4: "module-4-releases",
    5: "module-5-rollbacks",
    6: "module-6-dependencies",
    7: "module-7-hooks",
    8: "module-8-security",
    9: "module-9-advanced",
    10: "module-10-wargames",
}

MODULE_TITLES = {
    "module-1-basics": "Helm Basics",
    "module-2-values": "Values & Overrides",
    "module-3-templates": "Template Debugging",
    "module-4-releases": "Release Management",
    "module-5-rollbacks": "Rollbacks & Recovery",
    "module-6-dependencies": "Chart Dependencies",
    "module-7-hooks": "Helm Hooks",
    "module-8-security": "Security & Linting",
    "module-9-advanced": "Advanced Patterns",
    "module-10-wargames": "Production War Games",
}

COMMAND_GUIDES: dict[str, list[str]] = {
    "module-1-basics/level-2-install-first-chart": [
        "Change into the sandbox chart directory: `cd sandbox/current`",
        "Install the chart with a valid release name instead of a name that starts with a digit.",
        "Use: `helm install nginx-app ./broken -n helmissions --create-namespace`",
        "Verify with: `helm list -n helmissions` and `helm status nginx-app -n helmissions`",
    ],
    "module-1-basics/level-8-namespace-missing": [
        "This level is about the install command, not editing chart files.",
        "Install with namespace creation enabled: `helm install helmissions-app ./broken -n helmissions-extra --create-namespace`",
        "If you prefer, create the namespace first with kubectl and then install without `--create-namespace`.",
        "Verify the release exists in the target namespace with `helm list -n helmissions-extra`.",
    ],
    "module-1-basics/level-9-already-exists": [
        "The fix is to use an idempotent Helm command.",
        "Run: `helm upgrade --install webapp ./broken -n helmissions`",
        "This works whether the release already exists or not.",
        "Verify with `helm list -n helmissions` and `helm history webapp -n helmissions`.",
    ],
    "module-1-basics/level-10-set-wrong-key": [
        "The chart key is camelCase, so the override must match exactly.",
        "Run an upgrade with the corrected key: `helm upgrade --install helmissions-app ./broken -n helmissions --set replicaCount=5`",
        "Avoid `replicacount` or other case variants.",
        "Verify with `helm get values helmissions-app -n helmissions --all`.",
    ],
    "module-4-releases/level-10-uninstall-keep-history": [
        "This level is about restoring a release from kept history.",
        "Inspect history first: `helm history helmissions-app -n helmissions`",
        "Restore the release with `helm rollback helmissions-app <revision> -n helmissions`",
        "Verify the release returns to `deployed` state with `helm status helmissions-app -n helmissions`.",
    ],
    "module-5-rollbacks/level-1-simple-rollback": [
        "This level should be solved with a rollback command.",
        "Inspect revisions: `helm history helmissions-app -n helmissions`",
        "Rollback to the last known good revision: `helm rollback helmissions-app 1 -n helmissions`",
        "Verify the workload and values are restored after the rollback completes.",
    ],
}


def clean_module_directories() -> None:
    MODULES_DIR.mkdir(parents=True, exist_ok=True)
    for module_dir in MODULES_DIR.iterdir():
        if not module_dir.is_dir():
            continue
        for path in module_dir.iterdir():
            if path.is_dir():
                shutil.rmtree(path)


def parse_plan(path: Path) -> list[dict]:
    modules: list[dict] = []
    current_module: dict | None = None
    current_level: dict | None = None

    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        module_match = re.match(r"## Module (\d+) [—-] (.+)", line)
        if module_match and module_match.group(2) != "Summary":
            if current_level and current_module:
                current_module["levels"].append(finalize_level(current_level, current_module["name"]))
                current_level = None
            if current_module:
                modules.append(current_module)
            number = int(module_match.group(1))
            current_module = {
                "number": number,
                "name": MODULE_ORDER[number],
                "title": MODULE_TITLES[MODULE_ORDER[number]],
                "levels": [],
            }
            continue

        level_match = re.match(r"### Level (\d+) [—-] ([a-z0-9-]+)", line)
        if level_match:
            if current_level and current_module:
                current_module["levels"].append(finalize_level(current_level, current_module["name"]))
            current_level = {
                "number": int(level_match.group(1)),
                "slug": level_match.group(2),
            }
            continue

        if not current_level:
            continue

        if line.startswith("XP:"):
            xp_match = re.search(r"XP:\s*(\d+)", line)
            difficulty_match = re.search(r"Difficulty:\s*([a-zA-Z]+)", line)
            time_match = re.search(r"(?:Time|Time est\.)\s*:\s*([^|]+)$", line)
            if xp_match:
                current_level["xp"] = int(xp_match.group(1))
            if difficulty_match:
                current_level["difficulty"] = difficulty_match.group(1).strip().lower()
            if time_match:
                current_level["expected_time"] = time_match.group(1).strip()
            continue

        field_match = re.match(
            r"^(Name|Description|Broken state|Fix|Validate|Concepts|Hint 1|Hint 2|Hint 3|Debrief|Difficulty|Time|Time est\.)\s*:\s*(.*)$",
            line,
        )
        if not field_match:
            continue
        key = field_match.group(1)
        value = field_match.group(2).strip()
        mapping = {
            "Name": "name",
            "Description": "description",
            "Broken state": "broken_state",
            "Fix": "fix",
            "Validate": "validate",
            "Concepts": "concepts",
            "Hint 1": "hint_1",
            "Hint 2": "hint_2",
            "Hint 3": "hint_3",
            "Debrief": "debrief",
            "Difficulty": "difficulty",
            "Time": "expected_time",
            "Time est.": "expected_time",
        }
        current_level[mapping[key]] = value

    if current_level and current_module:
        current_module["levels"].append(finalize_level(current_level, current_module["name"]))
    if current_module:
        modules.append(current_module)
    return modules


def finalize_level(level: dict, module_name: str) -> dict:
    level["module"] = module_name
    level["dir_name"] = f"level-{level['number']}-{level['slug']}"
    level.setdefault("name", level["slug"].replace("-", " ").title())
    level.setdefault("description", level.get("broken_state", "Investigate the broken chart and restore the expected behavior."))
    level.setdefault("fix", "Repair the Helm chart so the release behaves as expected.")
    level.setdefault("validate", "Run the validator to confirm the chart is healthy.")
    level.setdefault("difficulty", "intermediate")
    level.setdefault("expected_time", "10m")
    level.setdefault("debrief", f"Review how the fix changed the Helm release for {level['name']}.")
    level.setdefault("hint_1", f"Start with the broken symptom: {level['description']}")
    level.setdefault("hint_2", f"Focus on the part described in the fix: {level['fix']}")
    level.setdefault("hint_3", f"Match the chart files with the expected healthy state for {level['slug']}.")
    for key, value in list(level.items()):
        if isinstance(value, str):
            cleaned = value.strip()
            if len(cleaned) >= 2 and cleaned[0] == cleaned[-1] and cleaned[0] in {'"', "'"}:
                cleaned = cleaned[1:-1]
            level[key] = cleaned
    concepts = level.get("concepts", "")
    level["concepts"] = [part.strip() for part in re.split(r",\s*", concepts) if part.strip()]
    level["xp"] = int(level.get("xp", 0))
    return level


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.rstrip() + "\n", encoding="utf-8")


def write_yaml(path: Path, data: dict) -> None:
    write_text(path, yaml.safe_dump(data, sort_keys=False, allow_unicode=True))


def write_shell(path: Path, content: str) -> None:
    write_text(path, textwrap.dedent(content).strip() + "\n")
    path.chmod(0o755)


def chart_name(level: dict) -> str:
    return level["slug"].replace("_", "-")


def mission_doc(level: dict) -> dict:
    return {
        "name": level["name"],
        "description": level["description"],
        "objective": level["fix"],
        "xp": level["xp"],
        "difficulty": level["difficulty"],
        "expected_time": level["expected_time"],
        "concepts": level["concepts"],
        "module": level["module"],
        "level": level["dir_name"],
    }


def default_values(level: dict) -> dict:
    return {
        "namespace": NS,
        "replicaCount": 1,
        "image": {
            "repository": "nginx",
            "tag": "latest",
            "pullPolicy": "IfNotPresent",
        },
        "service": {
            "type": "ClusterIP",
            "port": 80,
            "targetPort": 80,
        },
        "app": {
            "name": level["slug"].replace("-", "-"),
        },
        "containerPort": 80,
        "env": [],
        "config": {
            "message": f"{level['name']} ready",
        },
        "featureFlags": {
            "enabled": False,
        },
        "resources": {
            "limits": {"cpu": "250m", "memory": "256Mi"},
            "requests": {"cpu": "100m", "memory": "128Mi"},
        },
        "securityContext": {},
        "rbac": {
            "create": False,
        },
        "hooks": {
            "enabled": False,
            "weight": 0,
            "deletePolicy": "before-hook-creation,hook-succeeded",
        },
        "guard": {
            "expected": level["slug"],
            "actual": level["slug"],
        },
    }


HELPERS_TPL = """\
{{- define "helmissions.name" -}}
{{- default .Chart.Name .Values.app.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "helmissions.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "helmissions.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "helmissions.labels" -}}
app.kubernetes.io/name: {{ include "helmissions.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
"""

DEPLOYMENT_TPL = """\
{{- if ne .Values.guard.actual .Values.guard.expected }}
{{ fail (printf "guard mismatch: expected %s, got %s" .Values.guard.expected .Values.guard.actual) }}
{{- end }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "helmissions.fullname" . }}
  labels:
    {{- include "helmissions.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ include "helmissions.name" . }}
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ include "helmissions.name" . }}
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      {{- if .Values.rbac.create }}
      serviceAccountName: {{ include "helmissions.fullname" . }}
      {{- end }}
      containers:
        - name: app
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          {{- if .Values.securityContext }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          {{- end }}
          env:
            - name: APP_NAME
              value: {{ required "app.name is required" .Values.app.name | quote }}
            - name: CONFIG_MESSAGE
              valueFrom:
                configMapKeyRef:
                  name: {{ include "helmissions.fullname" . }}
                  key: message
            {{- range .Values.env }}
            - name: {{ .name | quote }}
              value: {{ .value | quote }}
            {{- end }}
          ports:
            - containerPort: {{ .Values.containerPort }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
"""

SERVICE_TPL = """\
apiVersion: v1
kind: Service
metadata:
  name: {{ include "helmissions.fullname" . }}
  labels:
    {{- include "helmissions.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  selector:
    app.kubernetes.io/name: {{ include "helmissions.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
"""

CONFIGMAP_TPL = """\
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "helmissions.fullname" . }}
data:
  message: {{ .Values.config.message | quote }}
"""

RBAC_TPL = """\
{{- if .Values.rbac.create }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "helmissions.fullname" . }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "helmissions.fullname" . }}
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "helmissions.fullname" . }}
subjects:
  - kind: ServiceAccount
    name: {{ include "helmissions.fullname" . }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ include "helmissions.fullname" . }}
{{- end }}
"""

HOOK_TPL = """\
{{- if .Values.hooks.enabled }}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "helmissions.fullname" . }}-hook
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "{{ .Values.hooks.weight }}"
    "helm.sh/hook-delete-policy": "{{ .Values.hooks.deletePolicy }}"
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: hook
          image: busybox:1.36
          command: ["sh", "-c", "echo hook executed"]
{{- end }}
"""

NOTES_TPL = """\
1. Inspect the rendered manifests:
   helm template {{ .Release.Name }} {{ .Chart.Name }}

2. Check the live release:
   helm status {{ .Release.Name }} -n {{ .Release.Namespace }}
"""


def chart_files(level: dict) -> dict[str, str]:
    values = default_values(level)
    chart = {
        "apiVersion": "v2",
        "name": chart_name(level),
        "description": f"Broken chart for {level['name']}",
        "type": "application",
        "version": "0.1.0",
        "appVersion": "1.0.0",
    }
    files = {
        "Chart.yaml": yaml.safe_dump(chart, sort_keys=False, allow_unicode=True),
        "values.yaml": yaml.safe_dump(values, sort_keys=False, allow_unicode=True),
        "templates/_helpers.tpl": HELPERS_TPL,
        "templates/deployment.yaml": DEPLOYMENT_TPL,
        "templates/service.yaml": SERVICE_TPL,
        "templates/configmap.yaml": CONFIGMAP_TPL,
        "templates/rbac.yaml": RBAC_TPL,
        "templates/hook-job.yaml": HOOK_TPL,
        "templates/NOTES.txt": NOTES_TPL,
        "values.schema.json": json.dumps(
            {
                "$schema": "https://json-schema.org/draft-07/schema#",
                "type": "object",
                "properties": {
                    "replicaCount": {"type": "integer", "minimum": 1},
                    "featureFlags": {
                        "type": "object",
                        "properties": {"enabled": {"type": "boolean"}},
                    },
                },
            },
            indent=2,
        ),
    }
    if level["module"] == "module-6-dependencies":
        files["Chart.lock"] = json.dumps({"generated": "local", "dependencies": [{"name": "subchart", "version": "0.1.0"}]}, indent=2)
        files["charts/subchart/Chart.yaml"] = textwrap.dedent(
            """\
            apiVersion: v2
            name: subchart
            version: 0.1.0
            type: application
            """
        )
        files["charts/subchart/values.yaml"] = "enabled: true\n"
        files["charts/subchart/templates/configmap.yaml"] = textwrap.dedent(
            """\
            apiVersion: v1
            kind: ConfigMap
            metadata:
              name: subchart-helper
            data:
              enabled: "true"
            """
        )
    if level["module"] == "module-9-advanced":
        files["helmfile.yaml"] = textwrap.dedent(
            f"""\
            releases:
              - name: {RELEASE}
                namespace: {NS}
                chart: ./broken
            """
        )
        files["post-renderer.sh"] = "#!/bin/bash\ncat\n"
    return files


def mutate_broken_files(level: dict, files: dict[str, str]) -> None:
    slug = level["slug"]
    module = level["module"]
    level_key = f"{module}/{level['dir_name']}"

    # Command-driven levels should keep a healthy chart; the challenge is the Helm command flow.
    if level_key in COMMAND_GUIDES:
        return

    if slug == "chart-structure":
        files["Chart.yaml"] = files["Chart.yaml"].replace("apiVersion: v2\n", "", 1)
        return
    if slug in {"wrong-image-tag", "wrong-image-prod"}:
        files["values.yaml"] = files["values.yaml"].replace("tag: latest\n", "tag: latestt\n", 1)
        return
    if slug in {"replica-type-error", "string-as-int"}:
        files["values.yaml"] = files["values.yaml"].replace("replicaCount: 1\n", 'replicaCount: "3"\n', 1)
        return
    if slug == "missing-required-value":
        files["values.yaml"] = re.sub(r"app:\n  name: .+\n", "app: {}\n", files["values.yaml"], count=1)
        return
    if slug == "wrong-service-type":
        files["values.yaml"] = files["values.yaml"].replace("type: ClusterIP\n", "type: ClusterIPP\n", 1)
        return
    if slug == "port-mismatch":
        files["values.yaml"] = files["values.yaml"].replace("targetPort: 80\n", "targetPort: 8080\n", 1)
        return
    if slug == "namespace-missing":
        files["values.yaml"] = files["values.yaml"].replace(f"namespace: {NS}\n", "namespace: helmissions-extra\n", 1)
        return
    if slug in {"bool-as-string", "helm-set-string"}:
        files["values.yaml"] = files["values.yaml"].replace("enabled: false\n", 'enabled: "false"\n', 1)
        return
    if slug in {"nil-nested-key", "nested-path-wrong", "values-typo", "set-wrong-key"}:
        files["values.yaml"] = files["values.yaml"].replace("replicaCount:", "replicacount:", 1)
        return
    if slug == "array-vs-string":
        files["values.yaml"] = files["values.yaml"].replace("env: []\n", "env: not-a-list\n", 1)
        return
    if slug == "values-indentation":
        files["values.yaml"] = files["values.yaml"].replace("service:\n  type:", "service:\n type:", 1)
        return
    if slug in {"missing-braces", "template-function-error", "include-missing"}:
        files["templates/deployment.yaml"] = files["templates/deployment.yaml"].replace("{{ include \"helmissions.fullname\" . }}", "{{ include \"helmissions.fullname\"  }}", 1)
        return
    if slug in {"yaml-indent-toYaml", "nindent-vs-indent", "configmap-multiline"}:
        files["templates/deployment.yaml"] = files["templates/deployment.yaml"].replace("nindent 12", "indent 3", 1)
        return
    if slug in {"release-name-context", "with-context", "named-template-args", "define-reuse"}:
        files["templates/service.yaml"] = files["templates/service.yaml"].replace("{{ include \"helmissions.fullname\" . }}", "{{ include \"helmissions.fullname\" $bad }}", 1)
        return
    if slug in {"pipe-order", "whitespace-control", "multiple-documents"}:
        files["templates/configmap.yaml"] = files["templates/configmap.yaml"].replace("| quote", "| upper | quote", 1)
        return
    if slug in {"required-blocks", "range-nil", "tpl-function", "lookup-function"}:
        files["values.yaml"] = files["values.yaml"].replace(f"actual: {slug}\n", "actual: not-the-expected-value\n", 1)
        return
    if module == "module-6-dependencies":
        if slug == "missing-lock":
            files.pop("Chart.lock", None)
        elif slug in {"wrong-version-range", "dep-not-updated"}:
            files["charts/subchart/Chart.yaml"] = files["charts/subchart/Chart.yaml"].replace("version: 0.1.0", "version: 9.9.9")
        else:
            files["values.yaml"] = files["values.yaml"].replace(f"actual: {slug}\n", "actual: dependency-broken\n", 1)
        return
    if module == "module-7-hooks":
        files["values.yaml"] = files["values.yaml"].replace("enabled: false\n", "enabled: true\n", 1).replace("weight: 0\n", "weight: bad\n", 1)
        return
    if module in {"module-4-releases", "module-5-rollbacks", "module-8-security", "module-9-advanced", "module-10-wargames"}:
        files["values.yaml"] = files["values.yaml"].replace(f"actual: {slug}\n", f"actual: broken-{slug}\n", 1)
        return
    files["values.yaml"] = files["values.yaml"].replace(f"actual: {slug}\n", "actual: mismatched\n", 1)


def build_hints(level: dict) -> tuple[str, str, str]:
    module_focus = {
        "module-1-basics": "Start with `helm lint`, `helm template`, or a fresh `helm install` against the broken chart.",
        "module-2-values": "Inspect `values.yaml` closely and compare the key path with the template fields consuming it.",
        "module-3-templates": "Render the chart first. Template and indentation failures are fastest to spot in `helm template` output.",
        "module-4-releases": "Look at live release state first: `helm list`, `helm status`, and `helm history` tell you more than the files alone.",
        "module-5-rollbacks": "This level is about revision history. Start with `helm history` and identify the good revision before changing anything.",
        "module-6-dependencies": "Check dependency metadata before editing manifests: `Chart.yaml`, `Chart.lock`, and `charts/` are the main suspects.",
        "module-7-hooks": "Hook levels usually fail before or after the main workload. Inspect annotations, Jobs, and hook ordering.",
        "module-8-security": "Use `helm lint` and then verify the rendered security-related resources or pod settings with kubectl.",
        "module-9-advanced": "These patterns rely on surrounding tooling. Read the chart plus the extra config files in the level directory.",
        "module-10-wargames": "Treat this like an incident. Establish what is broken first, then fix the highest-dependency problem before the rest.",
    }
    concept_text = ", ".join(level["concepts"][:3]) if level["concepts"] else "the Helm primitives involved"
    hint1 = f"{module_focus.get(level['module'], 'Start by reproducing the error with Helm commands.')} The broken state says: {level['description']}"
    hint2 = (
        f"The fix revolves around {concept_text}. Compare the current state with the objective: {level['fix']} "
        f"If the level is stateful, inspect the existing release history before reinstalling anything."
    )
    hint3 = (
        f"Concrete direction: {level['fix']}. When you think you have it, verify the result the same way the mission describes: {level['validate']}"
    )
    return hint1, hint2, hint3


def debrief_doc(level: dict) -> str:
    concepts = ", ".join(level["concepts"]) or "helm, kubectl"
    module_lesson = MODULE_TITLES.get(level["module"], level["module"])
    debrief_blurb = str(level["debrief"]).strip().rstrip(".")
    validate_commands = [
        "`helm status helmissions-app -n helmissions`",
        "`helm history helmissions-app -n helmissions`" if level["module"] in {"module-4-releases", "module-5-rollbacks"} else "`helm lint ./broken`",
        "`kubectl get all -n helmissions`",
    ]
    return textwrap.dedent(
        f"""\
        # {level["name"]}

        ## Situation
        {level["description"]} In this mission the broken state is intentional, and the point is not just to make Helm stop complaining. The real lesson is learning how Helm reports failure, where chart defects surface, and how release state and rendered manifests can drift apart when a deployment goes wrong.

        ## The Fix
        Primary action: {level["fix"]}

        A strong solution should leave both the chart and the cluster in a healthy state. In Helm that usually means checking the source of truth first, fixing the right file or release action, and then confirming that the next install, upgrade, rollback, or hook execution behaves the way you intended.

        ## What To Validate
        {level["validate"]}

        Helpful checks for this level:
        - {validate_commands[0]}
        - {validate_commands[1]}
        - {validate_commands[2]}

        ## Why It Matters
        {debrief_blurb}.

        This matters in {module_lesson.lower()} work because Helm failures are rarely just syntax errors. In real teams they show up during CI/CD runs, emergency rollbacks, environment promotion, or cluster changes that expose assumptions hidden in a chart. If you only patch the symptom in-cluster, the same bug usually comes back on the next deployment.

        A good operator learns the habit behind the fix: inspect the rendered output, understand the release history, and then make the smallest durable change that restores the expected behavior. That habit scales from a single broken values file all the way up to multi-service incident response.

        ## Concepts
        {concepts}
        """
    )


def common_mistakes_doc(level: dict) -> str:
    return textwrap.dedent(
        f"""\
        # Common Mistakes

        ## Mistake 1: Fixing the symptom, not the chart
        It is tempting to patch live resources with kubectl and stop there, but this level is about correcting the Helm source or release workflow so future installs, upgrades, and rollbacks stay healthy.

        ## Mistake 2: Skipping validation
        After changing the chart, run lint, template, or the live Helm command path that proves the release matches the objective: {level["validate"]}

        ## Mistake 3: Ignoring release history
        Many Helm problems are easier to solve when you inspect `helm status`, `helm get`, or `helm history` first. If you skip that context, it is easy to solve the wrong problem.
        """
    )


def solution_guide_doc(level: dict) -> str | None:
    key = f"{level['module']}/{level['dir_name']}"
    if key not in COMMAND_GUIDES:
        return None
    lines = "\n".join(f"{index}. {step}" for index, step in enumerate(COMMAND_GUIDES[key], start=1))
    return textwrap.dedent(
        f"""\
        # {level["name"]} Walkthrough

        This level is primarily solved with Helm commands rather than by editing the chart files directly.

        {lines}
        """
    )


def module_description_doc(module: dict) -> str:
    level_lines = "\n".join(
        f"- Level {level['number']}: {level['name']} ({level['dir_name']})"
        for level in module["levels"]
    )
    return textwrap.dedent(
        f"""\
        ════════════════════════════════════
        {module['title']}
        ════════════════════════════════════

        OVERVIEW
        Train on {module['title'].lower()} scenarios inside HelmMissions.

        SKILLS COVERED
        Helm troubleshooting, chart debugging, validation, and safe release workflows.

        LEVELS
        {level_lines}
        """
    )


def validator_requires_chart_sync(level: dict) -> bool:
    if level["module"] in {"module-4-releases", "module-5-rollbacks"}:
        return level["slug"] in {
            "upgrade-after-fail",
            "wait-timeout",
            "atomic-rollback",
            "crd-ordering",
            "helm-test",
            "notes-template",
            "cleanup-failed",
            "rollback-hooks",
        }
    if level["module"] == "module-7-hooks":
        return True
    return True


def validator_checks(level: dict) -> str:
    module = level["module"]
    slug = level["slug"]
    snippets: list[str] = []

    if validator_requires_chart_sync(level):
        snippets.append(
            """echo "🔍 Comparing fixed chart to reference solution..."
if ! diff -ru --exclude='Chart.lock' "$SOLUTION" "$BROKEN" >/tmp/helmissions-diff.txt 2>&1; then
  echo "❌ The chart in broken/ still differs from the expected fixed chart in solution/."
  exit 1
fi"""
        )

    if module == "module-6-dependencies":
        snippets.append(
            """echo "🔍 Validating dependency metadata..."
if [[ ! -f "$BROKEN/Chart.lock" ]]; then
  echo "❌ Chart.lock is missing"
  exit 1
fi
if ! helm dependency build "$BROKEN" >/tmp/helmissions-deps.txt 2>&1; then
  echo "❌ helm dependency build failed"
  cat /tmp/helmissions-deps.txt
  exit 1
fi"""
        )
    else:
        snippets.append(
            """echo "🔍 Linting chart..."
if ! helm lint "$BROKEN" >/tmp/helmissions-lint.txt 2>&1; then
  echo "❌ helm lint failed"
  cat /tmp/helmissions-lint.txt
  exit 1
fi
helm dependency build "$BROKEN" >/tmp/helmissions-deps.txt 2>&1 || true"""
        )

    if module == "module-4-releases":
        snippets.append(
            """echo "🔍 Inspecting release state..."
STATUS="$(helm status "$RELEASE" -n "$NS" -o json 2>/dev/null | jq -r '.info.status // empty')"
if [[ "$STATUS" != "deployed" ]]; then
  echo "❌ Release is not deployed (got: $STATUS)"
  exit 1
fi
HISTORY_COUNT="$(helm history "$RELEASE" -n "$NS" -o json 2>/dev/null | jq 'length')"
if [[ "${HISTORY_COUNT:-0}" -lt 1 ]]; then
  echo "❌ No release history found"
  exit 1
fi"""
        )
        if slug in {"atomic-rollback", "uninstall-keep-history", "history-inspection"}:
            snippets.append(
                """LATEST_DESC="$(helm history "$RELEASE" -n "$NS" -o json | jq -r '.[-1].description // ""')"
if [[ "$LATEST_DESC" != *"Rollback"* && "$LATEST_DESC" != *"upgrade"* && "$LATEST_DESC" != *"Upgrade"* ]]; then
  echo "❌ Expected a recovery action in helm history"
  exit 1
fi"""
            )
        if slug == "helm-test":
            snippets.append(
                """if ! helm test "$RELEASE" -n "$NS" >/tmp/helmissions-test.txt 2>&1; then
  echo "❌ helm test failed"
  cat /tmp/helmissions-test.txt
  exit 1
fi"""
            )
        if slug == "notes-template":
            snippets.append(
                """NOTES_OUTPUT="$(helm get notes "$RELEASE" -n "$NS" 2>/dev/null || true)"
if [[ -z "$NOTES_OUTPUT" ]]; then
  echo "❌ NOTES.txt did not render correctly"
  exit 1
fi"""
            )
        if slug == "crd-ordering":
            snippets.append(
                """if ! find "$BROKEN/crds" -name '*.yaml' -print -quit 2>/dev/null | grep -q .; then
  echo "❌ Expected a CRD file under broken/crds/"
  exit 1
fi"""
            )

    elif module == "module-5-rollbacks":
        snippets.append(
            """echo "🔍 Checking rollback history..."
STATUS="$(helm status "$RELEASE" -n "$NS" -o json 2>/dev/null | jq -r '.info.status // empty')"
if [[ "$STATUS" != "deployed" ]]; then
  echo "❌ Release is not deployed after rollback/recovery"
  exit 1
fi
LATEST_DESC="$(helm history "$RELEASE" -n "$NS" -o json 2>/dev/null | jq -r '.[-1].description // ""')"
if [[ "$LATEST_DESC" != *"Rollback"* && "$LATEST_DESC" != *"rollback"* && "$LATEST_DESC" != *"Upgrade"* ]]; then
  echo "❌ Expected the latest history entry to show rollback or recovery activity"
  exit 1
fi"""
        )
        if slug == "rollback-values":
            snippets.append(
                """REPLICAS="$(kubectl get deploy -n "$NS" -l app.kubernetes.io/instance="$RELEASE" -o jsonpath='{.items[0].spec.replicas}' 2>/dev/null || echo 0)"
if [[ "$REPLICAS" != "3" ]]; then
  echo "❌ Expected rollback to restore replicaCount=3"
  exit 1
fi"""
            )
        if slug == "simple-rollback":
            snippets.append(
                """IMAGE="$(kubectl get deploy -n "$NS" -l app.kubernetes.io/instance="$RELEASE" -o jsonpath='{.items[0].spec.template.spec.containers[0].image}' 2>/dev/null || true)"
if [[ "$IMAGE" == *"latestt"* ]]; then
  echo "❌ Rollback did not restore the good image"
  exit 1
fi"""
            )
        if slug == "history-limit":
            snippets.append(
                """COUNT="$(helm history "$RELEASE" -n "$NS" -o json | jq 'length')"
if [[ "${COUNT:-0}" -lt 5 ]]; then
  echo "❌ Expected multiple history entries to reason about history retention"
  exit 1
fi"""
            )

    elif module == "module-6-dependencies":
        snippets.append(
            """echo "🔍 Installing chart with dependencies..."
if ! helm upgrade --install "$RELEASE" "$BROKEN" -n "$NS" --create-namespace >/tmp/helmissions-upgrade.txt 2>&1; then
  echo "❌ helm upgrade --install failed after dependency resolution"
  cat /tmp/helmissions-upgrade.txt
  exit 1
fi"""
        )
    elif module == "module-7-hooks":
        snippets.append(
            """echo "🔍 Installing hook-enabled release..."
if ! helm upgrade --install "$RELEASE" "$BROKEN" -n "$NS" --create-namespace >/tmp/helmissions-hooks.txt 2>&1; then
  echo "❌ Hook-driven install/upgrade failed"
  cat /tmp/helmissions-hooks.txt
  exit 1
fi
RENDERED="$(helm template "$RELEASE" "$BROKEN" -n "$NS")"
if [[ "$RENDERED" != *"helm.sh/hook"* ]]; then
  echo "❌ No hook annotations found in rendered manifests"
  exit 1
fi"""
        )
        if slug == "deletion-policy":
            snippets.append(
                """if [[ "$RENDERED" != *"hook-delete-policy"* ]]; then
  echo "❌ Hook delete policy annotation missing"
  exit 1
fi"""
            )
        if slug in {"hook-weight", "hook-order-complex"}:
            snippets.append(
                """if [[ "$RENDERED" != *"hook-weight"* ]]; then
  echo "❌ Hook weights were not defined"
  exit 1
fi"""
            )
        if slug == "test-hook":
            snippets.append(
                """if ! helm test "$RELEASE" -n "$NS" >/tmp/helmissions-test.txt 2>&1; then
  echo "❌ helm test failed"
  cat /tmp/helmissions-test.txt
  exit 1
fi"""
            )
        if slug == "hook-rbac":
            snippets.append(
                """if ! kubectl get sa -n "$NS" >/tmp/helmissions-sa.txt 2>&1; then
  echo "❌ Expected hook service account resources to exist"
  exit 1
fi"""
            )
    else:
        snippets.append(
            """echo "🔍 Installing or upgrading release..."
if ! helm upgrade --install "$RELEASE" "$BROKEN" -n "$NS" --create-namespace >/tmp/helmissions-upgrade.txt 2>&1; then
  echo "❌ helm upgrade --install failed"
  cat /tmp/helmissions-upgrade.txt
  exit 1
fi

echo "🔍 Verifying live release status..."
STATUS="$(helm status "$RELEASE" -n "$NS" -o json 2>/dev/null | jq -r '.info.status // empty')"
if [[ "$STATUS" != "deployed" ]]; then
  echo "❌ Release not in deployed state (got: $STATUS)"
  exit 1
fi"""
        )

    snippets.append(
        """DEPLOY="$(kubectl get deploy -n "$NS" -l app.kubernetes.io/instance="$RELEASE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
if [[ -n "$DEPLOY" ]]; then
  kubectl rollout status "deployment/$DEPLOY" -n "$NS" --timeout=60s >/tmp/helmissions-rollout.txt 2>&1 || {
    echo "❌ Deployment did not become ready"
    cat /tmp/helmissions-rollout.txt
    exit 1
  }
fi

echo "✅ Level complete! Validation matched the behavior this mission is teaching."
"""
    )
    return "\n\n".join(snippets)


def validator_script(level: dict) -> str:
    return f"""\
#!/bin/bash
set -euo pipefail

RELEASE="{RELEASE}"
NS="{NS}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BROKEN="${{HELMMISSIONS_SANDBOX:-$ROOT/broken}}"
SOLUTION="${{HELMMISSIONS_SOLUTION:-$ROOT/solution}}"

{validator_checks(level)}
"""


def setup_steps(level: dict) -> str:
    module = level["module"]
    slug = level["slug"]

    if module == "module-4-releases":
        if slug in {"failed-release", "upgrade-after-fail", "pending-install"}:
            return """helm install "$RELEASE" "$ROOT/broken" -n "$NS" --create-namespace >/tmp/helmissions-setup.log 2>&1 || true"""
        if slug == "atomic-rollback":
            return """helm install "$RELEASE" "$ROOT/solution" -n "$NS" --create-namespace >/tmp/helmissions-setup.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/broken" -n "$NS" --atomic >/tmp/helmissions-atomic.log 2>&1 || true"""
        if slug == "uninstall-keep-history":
            return """helm install "$RELEASE" "$ROOT/solution" -n "$NS" --create-namespace >/tmp/helmissions-setup.log 2>&1 || true
helm uninstall "$RELEASE" -n "$NS" --keep-history >/tmp/helmissions-uninstall.log 2>&1 || true"""
        if slug == "resource-ownership":
            return """kubectl -n "$NS" create configmap helmissions-app-ownership --from-literal=message=conflict >/tmp/helmissions-cm.log 2>&1 || true"""
        if slug == "orphaned-resources":
            return """kubectl -n "$NS" create service clusterip helmissions-app-orphan --tcp=80:80 >/tmp/helmissions-svc.log 2>&1 || true"""
        if slug == "history-inspection":
            return """helm install "$RELEASE" "$ROOT/solution" -n "$NS" --create-namespace >/tmp/helmissions-setup.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/solution" -n "$NS" --set config.message=revision-2 >/tmp/helmissions-rev2.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/broken" -n "$NS" >/tmp/helmissions-rev3.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/solution" -n "$NS" --set config.message=revision-4 >/tmp/helmissions-rev4.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/solution" -n "$NS" --set config.message=revision-5 >/tmp/helmissions-rev5.log 2>&1 || true"""
        return """helm uninstall "$RELEASE" -n "$NS" >/dev/null 2>&1 || true
helm install "$RELEASE" "$ROOT/broken" -n "$NS" --create-namespace >/tmp/helmissions-setup.log 2>&1 || true"""

    if module == "module-5-rollbacks":
        if slug == "rollback-values":
            return """helm install "$RELEASE" "$ROOT/solution" -n "$NS" --create-namespace --set replicaCount=3 >/tmp/helmissions-setup.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/solution" -n "$NS" --set replicaCount=1 >/tmp/helmissions-upgrade.log 2>&1 || true"""
        if slug in {"simple-rollback", "specific-revision", "rollback-with-wait", "rollback-configmap"}:
            return """helm install "$RELEASE" "$ROOT/solution" -n "$NS" --create-namespace >/tmp/helmissions-setup.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/broken" -n "$NS" >/tmp/helmissions-upgrade.log 2>&1 || true"""
        if slug in {"history-limit", "upgrade-path", "production-incident", "revision-gaps"}:
            return """helm install "$RELEASE" "$ROOT/solution" -n "$NS" --create-namespace >/tmp/helmissions-setup.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/solution" -n "$NS" --set config.message=revision-2 >/tmp/helmissions-r2.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/broken" -n "$NS" >/tmp/helmissions-r3.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/solution" -n "$NS" --set config.message=revision-4 >/tmp/helmissions-r4.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/solution" -n "$NS" --set config.message=revision-5 >/tmp/helmissions-r5.log 2>&1 || true"""
        return """helm install "$RELEASE" "$ROOT/solution" -n "$NS" --create-namespace >/tmp/helmissions-setup.log 2>&1 || true
helm upgrade "$RELEASE" "$ROOT/broken" -n "$NS" >/tmp/helmissions-upgrade.log 2>&1 || true"""

    if module == "module-7-hooks":
        return """helm install "$RELEASE" "$ROOT/broken" -n "$NS" --create-namespace >/tmp/helmissions-setup.log 2>&1 || true"""

    if module in {"module-9-advanced", "module-10-wargames"}:
        return """helm install "$RELEASE" "$ROOT/broken" -n "$NS" --create-namespace >/tmp/helmissions-setup.log 2>&1 || true"""

    return """helm uninstall "$RELEASE" -n "$NS" >/dev/null 2>&1 || true
helm dependency build "$ROOT/broken" >/dev/null 2>&1 || true
helm upgrade --install "$RELEASE" "$ROOT/broken" -n "$NS" --create-namespace >/tmp/helmissions-setup.log 2>&1 || true"""


def setup_script(level: dict) -> str:
    return f"""\
#!/bin/bash
set -euo pipefail

NS="{NS}"
RELEASE="{RELEASE}"
ROOT="$(cd "$(dirname "$0")" && pwd)"

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
helm uninstall "$RELEASE" -n "$NS" >/dev/null 2>&1 || true
kubectl delete all --all -n "$NS" >/dev/null 2>&1 || true

{setup_steps(level)}
"""


def write_level(module_dir: Path, level: dict) -> None:
    level_dir = module_dir / level["dir_name"]
    level_dir.mkdir(parents=True, exist_ok=True)

    mission = mission_doc(level)
    hint1, hint2, hint3 = build_hints(level)
    write_yaml(level_dir / "mission.yaml", mission)
    write_text(level_dir / "hint-1.txt", hint1)
    write_text(level_dir / "hint-2.txt", hint2)
    write_text(level_dir / "hint-3.txt", hint3)
    write_text(level_dir / "debrief.md", debrief_doc(level))
    write_text(level_dir / "common-mistakes.md", common_mistakes_doc(level))
    guide_text = solution_guide_doc(level)
    if guide_text:
        write_text(level_dir / "solution-guide.md", guide_text)
    write_shell(level_dir / "validate.sh", validator_script(level))
    write_shell(level_dir / "setup.sh", setup_script(level))

    solution_files = chart_files(level)
    broken_files = dict(solution_files)
    mutate_broken_files(level, broken_files)

    for rel_path, content in solution_files.items():
        write_text(level_dir / "solution" / rel_path, content)
    for rel_path, content in broken_files.items():
        write_text(level_dir / "broken" / rel_path, content)
        write_text(level_dir / ".broken-source" / rel_path, content)


def generate_registry() -> Path:
    def sort_key(path: Path) -> tuple[int, str]:
        match = re.search(r"(\d+)", path.name)
        return (int(match.group(1)) if match else 9999, path.name)

    modules = []
    level_count = 0
    for module_dir in sorted((path for path in MODULES_DIR.iterdir() if path.is_dir()), key=sort_key):
        levels = []
        for level_dir in sorted((path for path in module_dir.iterdir() if path.is_dir()), key=sort_key):
            mission_path = level_dir / "mission.yaml"
            if not mission_path.exists():
                continue
            mission = yaml.safe_load(mission_path.read_text(encoding="utf-8")) or {}
            levels.append(
                {
                    "id": f"{module_dir.name}/{level_dir.name}",
                    "name": level_dir.name,
                    "path": str(level_dir.relative_to(ROOT)),
                    "mission": mission,
                }
            )
        if levels:
            modules.append({"name": module_dir.name, "levels": levels})
            level_count += len(levels)

    registry = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "level_count": level_count,
        "modules": modules,
    }
    write_text(LEVELS_JSON, json.dumps(registry, indent=2, ensure_ascii=False))
    return LEVELS_JSON


def build_all() -> Path:
    clean_module_directories()
    for module in parse_plan(PLAN_PATH):
        module_dir = MODULES_DIR / module["name"]
        module_dir.mkdir(parents=True, exist_ok=True)
        write_text(module_dir / "MODULE_DESCRIPTION.txt", module_description_doc(module))
        for level in module["levels"]:
            write_level(module_dir, level)
    return generate_registry()


def main() -> int:
    out = build_all()
    registry = json.loads(out.read_text(encoding="utf-8"))
    print(f"✅ Built HelmMissions levels → {out.relative_to(ROOT)}")
    print(f"   {len(registry['modules'])} modules, {registry['level_count']} levels")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
