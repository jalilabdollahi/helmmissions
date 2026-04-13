#!/usr/bin/env python3
"""Regenerate levels.json without rebuilding levels."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from scripts.build_levels import generate_registry


if __name__ == "__main__":
    out = generate_registry()
    reg = json.loads(out.read_text(encoding="utf-8"))
    print(f"✅ Registry written → {out.relative_to(ROOT)}")
    print(f"   {len(reg['modules'])} modules, {reg['level_count']} levels")
