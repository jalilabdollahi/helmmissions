#!/usr/bin/env python3
"""Safety checks for user-entered helm and kubectl commands."""

from __future__ import annotations

import re

from rich.console import Console
from rich.panel import Panel
from rich.prompt import Confirm

console = Console()

DANGEROUS_PATTERNS = [
    (
        r"kubectl\s+delete\s+namespace\s+(kube-system|kube-public|kube-node-lease|default)",
        "BLOCKED: deleting critical namespaces is not allowed.",
        "critical",
    ),
    (
        r"kubectl\s+delete\s+node",
        "BLOCKED: deleting nodes is not allowed.",
        "critical",
    ),
    (
        r"kubectl\s+delete\s+crd",
        "BLOCKED: deleting CRDs is not allowed.",
        "critical",
    ),
    (
        r"kubectl\s+delete\s+.*(\s--all-namespaces|\s-a(\s|$)|\s-[a-z]*a[a-z]*\s)",
        "BLOCKED: cluster-wide deletions are not allowed.",
        "critical",
    ),
    (
        r"kubectl\s+.*(--context|--kubeconfig|--cluster)(=|\s)",
        "BLOCKED: HelmMissions commands must run against the HelmMissions cluster only.",
        "critical",
    ),
    (
        r"kubectl\s+delete\s+namespace\s+helmissions",
        "Warning: deleting the helmissions namespace will erase the current level state.",
        "warning",
    ),
    (
        r"kubectl\s+delete\s+\w+\s+--all(\s|$)",
        "Warning: this deletes every resource of that type in the namespace.",
        "warning",
    ),
    (
        r"kubectl\s+delete\s+pv(\s|$)",
        "Warning: deleting PersistentVolumes may cause data loss.",
        "warning",
    ),
]

RISKY_PATTERNS = [
    r"kubectl\s+delete\s+namespace",
    r"kubectl\s+drain\s+",
    r"kubectl\s+cordon\s+",
]

ALLOWED_NAMESPACES = {"helmissions", "default", "kube-system"}
NAMESPACE_RE = re.compile(r"(?:\s-n|\s--namespace)(?:=|\s+)([^\s]+)")


def _namespace_allowed(namespace: str) -> bool:
    return namespace in ALLOWED_NAMESPACES or namespace.startswith("helmissions-")


def _check(command: str) -> tuple[bool, str, str]:
    lowered = command.lower().strip()
    for pattern, message, severity in DANGEROUS_PATTERNS:
        if re.search(pattern, lowered, re.IGNORECASE):
            return False, message, severity

    namespace_match = NAMESPACE_RE.search(" " + lowered)
    if namespace_match:
        namespace = namespace_match.group(1)
        if not _namespace_allowed(namespace):
            return False, f"Warning: this game expects namespace 'helmissions', not '{namespace}'.", "warning"

    return True, "", "safe"


def validate_kubectl_command(command: str, interactive: bool = True) -> bool:
    is_safe, message, severity = _check(command)
    if not is_safe and severity == "critical":
        console.print(
            Panel(
                f"[bold red]{message}[/bold red]\n\n[dim]Stay inside the training environment.[/dim]",
                title="[bold red]Safety Guard[/bold red]",
                border_style="red",
            )
        )
        return False

    if not is_safe and severity == "warning" and interactive:
        console.print(
            Panel(
                f"[bold yellow]{message}[/bold yellow]\n\n[dim]Proceed only if you mean to change the current exercise state.[/dim]",
                title="[bold yellow]Caution[/bold yellow]",
                border_style="yellow",
            )
        )
        if not Confirm.ask("Run this command?", default=False):
            return False

    if interactive:
        for pattern in RISKY_PATTERNS:
            if re.search(pattern, command, re.IGNORECASE):
                if not Confirm.ask("This is a risky kubectl operation. Continue?", default=False):
                    return False
                break

    return True


def print_safety_info() -> None:
    console.print(
        Panel(
            "Blocked: deleting system namespaces, nodes, CRDs, cluster-wide deletes, and switching clusters.\n"
            "Warned: deleting the helmissions namespace, --all deletes, PV deletes, and risky helm removals.",
            title="[bold bright_cyan]HelmMissions Safety[/bold bright_cyan]",
            border_style="bright_cyan",
        )
    )


def validate_helm_command(command: str, interactive: bool = True) -> bool:
    lowered = command.lower().strip()
    if re.search(r"\s--(kube-context|kubeconfig)(=|\s)", lowered):
        console.print(
            Panel(
                "[bold red]BLOCKED: HelmMissions commands must run against the HelmMissions cluster only.[/bold red]",
                title="[bold red]Safety Guard[/bold red]",
                border_style="red",
            )
        )
        return False
    namespace_match = NAMESPACE_RE.search(" " + lowered)
    if namespace_match and not _namespace_allowed(namespace_match.group(1)) and interactive:
        if not Confirm.ask(f"This game expects namespace 'helmissions' (or helmissions-*), not '{namespace_match.group(1)}'. Continue?", default=False):
            return False
    if re.search(r"helm\s+uninstall\s+.*(--all|-a)(?:\s|$)", lowered):
        namespace = namespace_match.group(1) if namespace_match else "default"
        if not namespace.startswith("helmissions"):
            console.print(
                Panel(
                    "[bold red]BLOCKED: helm uninstall --all is only allowed in the helmissions namespace.[/bold red]",
                    title="[bold red]Safety Guard[/bold red]",
                    border_style="red",
                )
            )
            return False
    if re.search(r"helm\s+repo\s+remove(?:\s|$)", lowered) or re.search(r"helm\s+plugin\s+remove(?:\s|$)", lowered):
        if interactive:
            console.print(
                Panel(
                    "[bold yellow]This Helm command changes local tooling state. Proceed only if you mean it.[/bold yellow]",
                    title="[bold yellow]Caution[/bold yellow]",
                    border_style="yellow",
                )
            )
            if not Confirm.ask("Run this helm command?", default=False):
                return False
    return True
