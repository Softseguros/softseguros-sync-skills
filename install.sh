#!/usr/bin/env bash
# Instala la skill «softseguros-sync» en los agentes que haya en este equipo.
#
#   ./install.sh                      instala en los agentes detectados
#   ./install.sh --agent claude       solo en Claude Code
#   ./install.sh --agent all          en los cuatro, estén o no instalados
#   ./install.sh --project            en el proyecto actual (./.claude/skills, ./.agents/skills…)
#   ./install.sh --uninstall          la quita
#   ./install.sh --dry-run            muestra qué haría, sin tocar nada
#
# Agentes: claude (Claude Code), codex (Codex CLI de OpenAI), opencode, hermes (Hermes Agent).
# Para ChatGPT y para claude.ai / Claude Desktop no hay carpeta: se sube dist/softseguros-sync.zip
# (ver README.md). `--agent chatgpt` o `--agent claude-web` muestran dónde está ese archivo.
#
# Sin el proyecto descargado (curl … | bash) baja la skill de GitHub. SOFTSEGUROS_SKILLS_REPO
# (owner/repo) y SOFTSEGUROS_SKILLS_REF (rama) permiten usar otro repositorio u otra rama.

set -euo pipefail

SKILL_NAME="softseguros-sync"
REPO_DEFAULT="Softseguros/softseguros-sync-skills"
REF_DEFAULT="main"

AGENTS_KNOWN="claude codex opencode hermes"

agents=""
scope="global"
custom_dir=""
action="install"
dry_run=0
tmp_dir=""

say()  { printf '%s\n' "$*"; }
warn() { printf 'aviso: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

usage() {
  sed -n '2,17p' "${BASH_SOURCE[0]:-$0}" 2>/dev/null | sed 's/^# \{0,1\}//' || true
  cat <<'EOF'

Opciones:
  -a, --agent LISTA   claude, codex, opencode, hermes, all o auto (por defecto). Se puede repetir
                      o separar con comas: --agent claude,opencode
      --project       instala en el directorio actual en vez de en tu carpeta de usuario
      --dir RUTA      instala en esa carpeta de skills (para cualquier otro agente)
      --uninstall     quita la skill de los destinos elegidos
      --dry-run       no cambia nada; solo muestra los destinos
  -h, --help          esta ayuda
EOF
}

cleanup() { if [ -n "$tmp_dir" ] && [ -d "$tmp_dir" ]; then rm -rf "$tmp_dir"; fi; }
trap cleanup EXIT

add_agents() {
  local item
  for item in $(printf '%s' "$1" | tr ',' ' '); do agents="$agents $item"; done
}

while [ $# -gt 0 ]; do
  case "$1" in
    -a|--agent)   [ $# -ge 2 ] || die "--agent necesita un valor"; add_agents "$2"; shift 2 ;;
    --agent=*)    add_agents "${1#*=}"; shift ;;
    --project)    scope="project"; shift ;;
    --dir)        [ $# -ge 2 ] || die "--dir necesita una ruta"; custom_dir="$2"; shift 2 ;;
    --dir=*)      custom_dir="${1#*=}"; shift ;;
    --uninstall)  action="uninstall"; shift ;;
    --dry-run)    dry_run=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)            die "opción desconocida: $1 (usa --help)" ;;
  esac
done

# --- dónde vive la skill de cada agente ---------------------------------------------------------

home_dir="${HOME:?HOME no está definido}"

agent_label() {
  case "$1" in
    claude)   echo "Claude Code" ;;
    codex)    echo "Codex CLI" ;;
    opencode) echo "opencode" ;;
    hermes)   echo "Hermes Agent" ;;
  esac
}

# Carpeta que delata que el agente está instalado.
agent_home() {
  case "$1" in
    claude)   echo "${CLAUDE_CONFIG_DIR:-$home_dir/.claude}" ;;
    codex)    echo "${CODEX_HOME:-$home_dir/.codex}" ;;
    opencode) echo "${XDG_CONFIG_HOME:-$home_dir/.config}/opencode" ;;
    hermes)   echo "${HERMES_HOME:-$home_dir/.hermes}" ;;
  esac
}

agent_command() {
  case "$1" in
    claude) echo claude ;; codex) echo codex ;; opencode) echo opencode ;; hermes) echo hermes ;;
  esac
}

# Carpeta de skills del agente; vacío = ese agente no tiene carpeta en este alcance.
skills_root() {
  local agent="$1"
  if [ "$scope" = "project" ]; then
    case "$agent" in
      claude)   echo "$PWD/.claude/skills" ;;
      codex)    echo "$PWD/.agents/skills" ;;
      opencode) echo "$PWD/.opencode/skills" ;;
      hermes)   echo "" ;;
    esac
    return
  fi
  case "$agent" in
    claude)   echo "$(agent_home claude)/skills" ;;
    codex)    echo "${CODEX_SKILLS_DIR:-$home_dir/.agents/skills}" ;;
    opencode) echo "$(agent_home opencode)/skills" ;;
    hermes)   echo "$(agent_home hermes)/skills" ;;
  esac
}

is_detected() {
  [ -d "$(agent_home "$1")" ] || command -v "$(agent_command "$1")" >/dev/null 2>&1
}

# --- de dónde sale la skill ---------------------------------------------------------------------

script_path="${BASH_SOURCE[0]:-}"
script_dir=""
if [ -n "$script_path" ] && [ -f "$script_path" ]; then
  script_dir="$(cd "$(dirname "$script_path")" && pwd)"
fi

source_dir=""
resolve_source() {
  if [ -n "$script_dir" ] && [ -f "$script_dir/skills/$SKILL_NAME/SKILL.md" ]; then
    source_dir="$script_dir/skills/$SKILL_NAME"
    return
  fi
  local repo="${SOFTSEGUROS_SKILLS_REPO:-$REPO_DEFAULT}"
  local ref="${SOFTSEGUROS_SKILLS_REF:-$REF_DEFAULT}"
  [ -n "$repo" ] || die "no encuentro skills/$SKILL_NAME junto a este script. Descarga el proyecto completo, o indica el repositorio: SOFTSEGUROS_SKILLS_REPO=owner/repo"
  command -v curl >/dev/null 2>&1 || die "hace falta curl para descargar la skill"
  command -v tar  >/dev/null 2>&1 || die "hace falta tar para descomprimir la skill"
  tmp_dir="$(mktemp -d)"
  say "Descargando $repo ($ref)…"
  curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/$ref" -o "$tmp_dir/skills.tar.gz" \
    || die "no pude descargar $repo. Si el repositorio es privado, clónalo y ejecuta ./install.sh desde ahí."
  tar -xzf "$tmp_dir/skills.tar.gz" -C "$tmp_dir"
  source_dir="$(find "$tmp_dir" -type f -path "*/skills/$SKILL_NAME/SKILL.md" -print | head -n 1)"
  [ -n "$source_dir" ] || die "el repositorio no trae skills/$SKILL_NAME/SKILL.md"
  source_dir="$(dirname "$source_dir")"
}

# --- instalar / quitar --------------------------------------------------------------------------

# Solo se reemplaza o borra una carpeta que sea esta misma skill.
is_our_skill() {
  [ -f "$1/SKILL.md" ] && grep -q "^name: $SKILL_NAME\$" "$1/SKILL.md"
}

install_into() {
  local root="$1" label="$2" dest="$1/$SKILL_NAME"
  if [ -e "$dest" ] && ! is_our_skill "$dest"; then
    warn "$dest existe y no es esta skill: no la toco ($label)"
    return 1
  fi
  if [ "$dry_run" -eq 1 ]; then
    say "  [simulación] $label → $dest"
    return 0
  fi
  mkdir -p "$root"
  rm -rf "$dest"
  mkdir -p "$dest"
  # Todo menos las pruebas (evals/), que no hacen falta para usar la skill.
  (cd "$source_dir" && tar -cf - --exclude './evals' .) | (cd "$dest" && tar -xf -)
  say "  ✓ $label → $dest"
}

uninstall_from() {
  local root="$1" label="$2" dest="$1/$SKILL_NAME"
  if [ ! -e "$dest" ]; then
    say "  · $label: no estaba instalada"
    return 0
  fi
  if ! is_our_skill "$dest"; then
    warn "$dest no es esta skill: no la toco ($label)"
    return 1
  fi
  if [ "$dry_run" -eq 1 ]; then
    say "  [simulación] quitaría $dest"
    return 0
  fi
  rm -rf "$dest"
  say "  ✓ $label: quitada de $dest"
}

show_upload_help() {
  local zip=""
  [ -n "$script_dir" ] && [ -f "$script_dir/dist/$SKILL_NAME.zip" ] && zip="$script_dir/dist/$SKILL_NAME.zip"
  say "  · $1 no lee carpetas del equipo: la skill se sube como archivo."
  if [ -n "$zip" ]; then say "    Archivo: $zip"; else say "    Archivo: dist/$SKILL_NAME.zip del proyecto"; fi
  say "    Pasos en README.md, sección «ChatGPT y claude.ai»."
}

# --- qué agentes --------------------------------------------------------------------------------

agents="$(printf '%s' "$agents" | tr -s ' ' | sed 's/^ //')"
[ -n "$agents" ] || agents="auto"

selected=""
upload_only=""
for agent in $agents; do
  case "$agent" in
    auto)
      for known in $AGENTS_KNOWN; do
        if is_detected "$known"; then selected="$selected $known"; fi
      done
      ;;
    all)                     selected="$selected $AGENTS_KNOWN" ;;
    claude|claude-code)      selected="$selected claude" ;;
    codex)                   selected="$selected codex" ;;
    opencode)                selected="$selected opencode" ;;
    hermes|hermes-agent)     selected="$selected hermes" ;;
    chatgpt)                 upload_only="$upload_only ChatGPT" ;;
    claude-web|claude-ai|claude-desktop) upload_only="$upload_only claude.ai" ;;
    *) die "agente desconocido: $agent (claude, codex, opencode, hermes, all, auto)" ;;
  esac
done
# sin repetidos, en orden
selected="$(printf '%s\n' $selected | awk 'NF && !seen[$0]++' | tr '\n' ' ')"

if [ -z "${selected// /}" ] && [ -z "$custom_dir" ] && [ -z "$upload_only" ]; then
  say "No detecté Claude Code, Codex, opencode ni Hermes en este equipo."
  say "Elige uno con --agent (claude, codex, opencode, hermes, all) o una carpeta con --dir."
  say "Para ChatGPT o claude.ai sube dist/$SKILL_NAME.zip (ver README.md)."
  exit 1
fi

[ "$action" = "install" ] && [ -n "${selected// /}$custom_dir" ] && resolve_source

if [ "$action" = "install" ]; then say "Instalando «$SKILL_NAME»:"; else say "Quitando «$SKILL_NAME»:"; fi

failed=0
done_any=0
for agent in $selected; do
  root="$(skills_root "$agent")"
  label="$(agent_label "$agent")"
  if [ -z "$root" ]; then
    say "  · $label no tiene carpeta de skills por proyecto: usa la instalación global"
    continue
  fi
  if [ "$action" = "install" ]; then
    install_into "$root" "$label" || failed=1
  else
    uninstall_from "$root" "$label" || failed=1
  fi
  done_any=1
done

if [ -n "$custom_dir" ]; then
  if [ "$action" = "install" ]; then
    install_into "$custom_dir" "carpeta indicada" || failed=1
  else
    uninstall_from "$custom_dir" "carpeta indicada" || failed=1
  fi
  done_any=1
fi

for target in $upload_only; do show_upload_help "$target"; done

if [ "$action" = "install" ] && [ "$done_any" -eq 1 ] && [ "$dry_run" -eq 0 ] && [ "$failed" -eq 0 ]; then
  cat <<'EOF'

Listo. Dos cosas más:
  1. Reinicia el agente (o abre una sesión nueva) para que cargue la skill.
  2. La skill guía el uso del MCP del Sincronizador; si aún no lo tienes conectado, sigue
     docs/conectar-mcp.md (URL: https://sync-api.softseguros.com/mcp).
EOF
fi

exit "$failed"
