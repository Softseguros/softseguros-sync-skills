#!/usr/bin/env python3
"""Valida la skill y arma los archivos para subir a ChatGPT y a claude.ai.

Uso:
    python3 scripts/build.py

Escribe en dist/:
    softseguros-sync.zip     una carpeta `softseguros-sync/` con SKILL.md y references/
    softseguros-sync.skill   el mismo contenido con la extensión que reconoce Claude

Las pruebas (evals/) no se empaquetan. Solo usa la biblioteca estándar.
"""

from __future__ import annotations

import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"
DIST = ROOT / "dist"
SKIPPED_DIRS = {"evals", "__pycache__", "node_modules"}
# Fecha fija: dos compilaciones del mismo contenido dan el mismo archivo.
FIXED_DATE = (2026, 1, 1, 0, 0, 0)


def packaged_files(skill: Path) -> list[Path]:
    files = []
    for path in sorted(skill.rglob("*")):
        relative = path.relative_to(skill)
        if path.is_file() and not SKIPPED_DIRS & set(relative.parts) and path.name != ".DS_Store":
            files.append(path)
    return files


def write_archive(skill: Path, target: Path) -> None:
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in packaged_files(skill):
            info = zipfile.ZipInfo(f"{skill.name}/{path.relative_to(skill).as_posix()}", FIXED_DATE)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16  # legible para todos: algunos cargadores lo exigen
            archive.writestr(info, path.read_bytes())


def main() -> int:
    validation = subprocess.run([sys.executable, str(Path(__file__).with_name("validate.py"))])
    if validation.returncode != 0:
        print("No se empaqueta: corrige primero los problemas de arriba.")
        return 1
    DIST.mkdir(exist_ok=True)
    for skill in sorted(path for path in SKILLS.iterdir() if (path / "SKILL.md").is_file()):
        for extension in ("zip", "skill"):
            target = DIST / f"{skill.name}.{extension}"
            write_archive(skill, target)
            print(f"  {target.relative_to(ROOT)}  ({target.stat().st_size // 1024} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
