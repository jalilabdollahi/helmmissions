#!/usr/bin/env python3
"""Regenerate levels.json (a static index of all missions, used by docs/tools — the game scans modules/ directly)."""

from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
MODULES_DIR = ROOT / "modules"
LEVELS_JSON = ROOT / "levels.json"


def _sort_key(path: Path) -> tuple[int, str]:
    match = re.search(r"(\d+)", path.name)
    return (int(match.group(1)) if match else 9999, path.name)


def generate_registry() -> Path:
    modules = []
    level_count = 0
    total_xp = 0
    for module_dir in sorted((p for p in MODULES_DIR.iterdir() if p.is_dir()), key=_sort_key):
        levels = []
        for level_dir in sorted((p for p in module_dir.iterdir() if p.is_dir()), key=_sort_key):
            mission_path = level_dir / "mission.yaml"
            if not mission_path.exists():
                continue
            mission = yaml.safe_load(mission_path.read_text(encoding="utf-8")) or {}
            levels.append({"id": f"{module_dir.name}/{level_dir.name}", "name": level_dir.name,
                           "path": str(level_dir.relative_to(ROOT)), "mission": mission})
            total_xp += int(mission.get("xp", 0))
        if levels:
            modules.append({"name": module_dir.name, "xp": sum(int(lv["mission"].get("xp", 0)) for lv in levels), "levels": levels})
            level_count += len(levels)
    registry = {"generated_at": datetime.now(timezone.utc).isoformat(), "level_count": level_count,
                "total_xp": total_xp, "modules": modules}
    LEVELS_JSON.write_text(json.dumps(registry, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return LEVELS_JSON


if __name__ == "__main__":
    out = generate_registry()
    reg = json.loads(out.read_text(encoding="utf-8"))
    print(f"✅ Registry written → {out.relative_to(ROOT)}")
    print(f"   {len(reg['modules'])} modules, {reg['level_count']} levels, {reg['total_xp']:,} XP")
