#!/usr/bin/env python3
"""Revisa que la skill esté bien formada y siga de acuerdo con las tools reales del MCP.

Uso:
    python3 scripts/validate.py

Comprueba:
  1. El frontmatter de SKILL.md (nombre, descripción, claves permitidas por el estándar Agent Skills).
  2. Que SKILL.md no pase de 500 líneas y que las referencias largas tengan índice.
  3. Que cada enlace relativo apunte a un archivo que existe.
  4. Que cada tool nombrada exista en `scripts/tool-catalog.json`, que cada tool del catálogo esté
     explicada en la skill y que los parámetros escritos como `tool(parametro=…)` existan.
  5. Que cada caso de `evals/` tenga prompt, descripción y al menos una afirmación a verificar.

Sale con código 1 si hay errores. Solo usa la biblioteca estándar.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"
CATALOG = Path(__file__).with_name("tool-catalog.json")

ALLOWED_KEYS = {"name", "description", "license", "allowed-tools", "metadata", "compatibility"}
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
TOOL_LIKE = re.compile(r"^(search|get|download|create|update|confirm|list|link|mark|add|preview|set)_[a-z_]+$")
# Valores de parámetros que parecen nombres de tool y no lo son.
NOT_TOOLS = {"link_pdf"}
MAX_SKILL_LINES = 500
TOC_FROM_LINES = 300


def frontmatter(text: str) -> tuple[dict[str, str], str]:
    """Las claves de primer nivel del frontmatter (los bloques `>-` unidos en una línea) y el cuerpo."""
    match = re.match(r"^---\n(.*?)\n---\n?(.*)$", text, re.DOTALL)
    if not match:
        raise ValueError("SKILL.md no empieza con un bloque de frontmatter entre ---")
    fields: dict[str, str] = {}
    key = None
    for line in match.group(1).splitlines():
        top = re.match(r"^([A-Za-z][\w-]*):\s*(.*)$", line)
        if top:
            key = top.group(1)
            value = top.group(2).strip()
            fields[key] = "" if value in {">", ">-", "|", "|-"} else value
        elif key and line.startswith((" ", "\t")):
            fields[key] = (fields[key] + " " + line.strip()).strip()
    return fields, match.group(2)


def check_frontmatter(skill: Path, errors: list[str]) -> None:
    text = (skill / "SKILL.md").read_text(encoding="utf-8")
    try:
        fields, body = frontmatter(text)
    except ValueError as exc:
        errors.append(f"{skill.name}: {exc}")
        return
    for key in sorted(set(fields) - ALLOWED_KEYS):
        errors.append(f"{skill.name}: clave de frontmatter no permitida: {key}")
    name = fields.get("name", "").strip("\"'")
    if not NAME_RE.match(name) or len(name) > 64:
        errors.append(f"{skill.name}: name debe ser minúsculas-con-guiones, máximo 64 caracteres")
    if name != skill.name:
        errors.append(f"{skill.name}: name ({name!r}) debe ser igual al nombre de la carpeta")
    description = fields.get("description", "")
    if not description:
        errors.append(f"{skill.name}: falta description")
    if len(description) > 1024:
        errors.append(f"{skill.name}: description tiene {len(description)} caracteres (máximo 1024)")
    if "<" in description or ">" in description:
        errors.append(f"{skill.name}: description no puede llevar < ni >")
    lines = body.count("\n") + 1
    if lines > MAX_SKILL_LINES:
        errors.append(f"{skill.name}: SKILL.md tiene {lines} líneas de cuerpo (máximo {MAX_SKILL_LINES})")


def markdown_files(skill: Path) -> list[Path]:
    return [skill / "SKILL.md", *sorted((skill / "references").glob("*.md"))]


def check_links(skill: Path, errors: list[str]) -> None:
    for path in markdown_files(skill):
        text = path.read_text(encoding="utf-8")
        for target in re.findall(r"\]\(([^)#\s]+)(?:#[^)]*)?\)", text):
            if re.match(r"^[a-z]+:", target):
                continue
            if not (path.parent / target).exists():
                errors.append(f"{path.relative_to(ROOT)}: el enlace {target} no existe")
        if path.name != "SKILL.md" and text.count("\n") > TOC_FROM_LINES and "## Contenido" not in text:
            errors.append(f"{path.relative_to(ROOT)}: más de {TOC_FROM_LINES} líneas y sin «## Contenido»")


def check_tools(skill: Path, errors: list[str]) -> None:
    catalog = {tool["name"]: tool for tool in json.loads(CATALOG.read_text(encoding="utf-8"))["tools"]}
    mentioned: set[str] = set()
    for path in markdown_files(skill):
        text = path.read_text(encoding="utf-8")
        for token in re.findall(r"`([^`\n]+)`", text):
            call = re.match(r"^([a-z_]+)\s*(?:\((.*)\))?$", token.strip(), re.DOTALL)
            if not call or not TOOL_LIKE.match(call.group(1)) or call.group(1) in NOT_TOOLS:
                continue
            name, arguments = call.group(1), call.group(2) or ""
            if name not in catalog:
                errors.append(f"{path.relative_to(ROOT)}: nombra la tool `{name}`, que no está en el catálogo")
                continue
            mentioned.add(name)
            known = {parameter["name"] for parameter in catalog[name]["parameters"]}
            for parameter in re.findall(r"(?:^|[,(\s])([a-z_]+)\s*=", arguments):
                if parameter not in known:
                    errors.append(
                        f"{path.relative_to(ROOT)}: `{name}` no tiene el parámetro `{parameter}`"
                    )
    for name in sorted(set(catalog) - mentioned):
        errors.append(f"{skill.name}: la tool `{name}` del catálogo no aparece en la skill")


def check_evals(skill: Path, errors: list[str]) -> None:
    evals = skill / "evals"
    if not evals.is_dir():
        return
    for case in sorted(path for path in evals.iterdir() if path.is_dir()):
        for required in ("prompt.md", "case.yaml"):
            if not (case / required).is_file():
                errors.append(f"evals/{case.name}: falta {required}")
        if not list((case / "graders").glob("*.md")):
            errors.append(f"evals/{case.name}: no tiene afirmaciones en graders/")
        declared = re.search(r"^name:\s*(\S+)", (case / "case.yaml").read_text(encoding="utf-8"), re.M)
        if not declared or declared.group(1) != case.name:
            errors.append(f"evals/{case.name}: name de case.yaml distinto del nombre de la carpeta")


def main() -> int:
    errors: list[str] = []
    skills = sorted(path for path in SKILLS.iterdir() if (path / "SKILL.md").is_file())
    if not skills:
        errors.append("no hay ninguna skill en skills/")
    for skill in skills:
        check_frontmatter(skill, errors)
        check_links(skill, errors)
        check_tools(skill, errors)
        check_evals(skill, errors)
    if errors:
        print(f"{len(errors)} problema(s):")
        for error in errors:
            print(f"  - {error}")
        return 1
    print(f"OK: {len(skills)} skill(s), sin problemas.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
