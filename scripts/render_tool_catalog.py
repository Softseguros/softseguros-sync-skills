#!/usr/bin/env python3
"""Escribe en Markdown el catálogo de tools tal como lo ve un modelo conectado a `/mcp`.

Uso:
    python3 scripts/render_tool_catalog.py > docs/tools-del-mcp.md
    python3 scripts/render_tool_catalog.py --only-any-member > …   # lo que ve un rol que no opera pólizas

Lee `scripts/tool-catalog.json`. El resultado sirve como
referencia y como archivo de entrada de las pruebas de `skills/softseguros-sync/evals/`: así una
prueba «en papel» parte de las mismas descripciones que el servidor entrega.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

CATALOG = Path(__file__).with_name("tool-catalog.json")


def render(tools: list[dict]) -> str:
    lines = [
        "# Tools del MCP «Softseguros Sync» (`/mcp`)",
        "",
        "Nombre, parámetros y descripción de cada tool, tal como el servidor los entrega al modelo.",
        "Generado con `scripts/render_tool_catalog.py`; no se edita a mano.",
        "",
    ]
    for tool in tools:
        signature = ", ".join(
            f"{p['name']}: {p['type']}" + ("" if p["required"] else f" = {p['default']}")
            for p in tool["parameters"]
        )
        lines += [f"## `{tool['name']}({signature})`", "", tool["description"] or "(sin descripción)", ""]
    return "\n".join(lines)


def main() -> int:
    tools = json.loads(CATALOG.read_text(encoding="utf-8"))["tools"]
    if "--only-any-member" in sys.argv[1:]:
        tools = [tool for tool in tools if not tool["restricted"]]
    sys.stdout.write(render(tools))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
