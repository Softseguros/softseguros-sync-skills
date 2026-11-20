#!/usr/bin/env python3
"""Escribe en Markdown el catálogo de tools tal como lo ve un modelo conectado a `/mcp`.

Uso:
    python3 scripts/render_tool_catalog.py > docs/tools-del-mcp.md
    python3 scripts/render_tool_catalog.py --only-any-member > …   # solo las tools de cualquier miembro
    python3 scripts/render_tool_catalog.py --role reader > …       # lo que ve un rol de la agencia

Lee `scripts/tool-catalog.json`. El resultado sirve como
referencia y como archivo de entrada de las pruebas de `skills/softseguros-sync/evals/`: así una
prueba «en papel» parte de las mismas descripciones que el servidor entrega.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

CATALOG = Path(__file__).with_name("tool-catalog.json")

# Los permisos (scopes) que piden las tools del catálogo, por rol de la agencia. Es solo la parte del mapa del
# servidor (app/auth/scopes.py, ROLE_SCOPES) que el catálogo usa: una tool sin scopes es de cualquier miembro.
ROLE_SCOPES = {
    "admin": {"policies.operate", "sellers.assign"},
    "operations_commissions": {"policies.operate", "sellers.assign"},
    "operations": {"policies.operate", "sellers.assign"},
    "commissions": {"sellers.assign"},
    "reader": set(),
}


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
    arguments = sys.argv[1:]
    if "--only-any-member" in arguments:
        tools = [tool for tool in tools if not tool["scopes"]]
    if "--role" in arguments:
        position = arguments.index("--role") + 1
        role = arguments[position] if position < len(arguments) else ""
        if role not in ROLE_SCOPES:
            sys.stderr.write(f"--role debe ser uno de: {', '.join(ROLE_SCOPES)}\n")
            return 2
        tools = [tool for tool in tools if set(tool["scopes"]) <= ROLE_SCOPES[role]]
    sys.stdout.write(render(tools))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
