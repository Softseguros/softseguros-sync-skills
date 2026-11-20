# Skill del Sincronizador de Softseguros

Una skill (formato abierto Agent Skills, `SKILL.md`) que le enseña a un agente de IA a usar bien
el MCP del Sincronizador de Softseguros (`https://sync-api.softseguros.com/mcp`): qué tool usar
para cada cosa, cómo buscar sin quedarse en vacío, qué significa cada estado, cómo crear una
póliza desde un PDF o aplicar un anexo, cómo leer el correo de la agencia, cómo asignar vendedores
a las pólizas y qué hacer con cada error.

Funciona en Claude (Code, Desktop y claude.ai), ChatGPT y Codex, opencode y Hermes Agent, porque
todos leen el mismo formato.

Necesitas una cuenta en el Sincronizador de Softseguros: la skill guía el uso del MCP, no da
acceso a él.

## Instalar

### Con un comando (Claude Code, Codex, opencode, Hermes)

```bash
curl -fsSL https://raw.githubusercontent.com/Softseguros/softseguros-sync-skills/main/install.sh | bash
```

Detecta qué agentes hay en el equipo e instala la skill en cada uno. Para elegir uno, o con el
repositorio ya clonado:

```bash
./install.sh --agent claude
```

```bash
./install.sh --agent all
```

En Windows (PowerShell), con el repositorio clonado:

```powershell
.\install.ps1
```

| Agente | `--agent` | Dónde queda |
| --- | --- | --- |
| Claude Code | `claude` | `~/.claude/skills/softseguros-sync/` |
| Codex CLI (OpenAI) | `codex` | `~/.agents/skills/softseguros-sync/` |
| opencode | `opencode` | `~/.config/opencode/skills/softseguros-sync/` |
| Hermes Agent | `hermes` | `~/.hermes/skills/softseguros-sync/` |
| Otro agente | `--dir <carpeta de skills>` | la carpeta que indiques |

Otras opciones: `--project` (instala en el proyecto actual: `.claude/skills`, `.agents/skills`,
`.opencode/skills`), `--uninstall`, `--dry-run`, `--help`. Reinstalar reemplaza la versión
anterior; el instalador nunca toca una carpeta que no sea esta skill.

Después de instalar, reinicia el agente.

Una versión antigua de Codex que todavía lea `~/.codex/skills`:

```bash
CODEX_SKILLS_DIR="$HOME/.codex/skills" ./install.sh --agent codex
```

### Otras formas

Con el instalador comunitario de skills:

```bash
npx skills add Softseguros/softseguros-sync-skills
```

En Claude Code, como plugin:

```
/plugin marketplace add Softseguros/softseguros-sync-skills
/plugin install softseguros-sync@softseguros
```

### ChatGPT y claude.ai (se sube un archivo)

Estas dos aplicaciones no leen carpetas del equipo: la skill se sube.

- **claude.ai y Claude Desktop:** Ajustes › Capacidades › Skills › Subir skill, y elige
  `dist/softseguros-sync.zip` (o abre `dist/softseguros-sync.skill`).
- **ChatGPT:** en el apartado de Skills, Crear › Subir desde el equipo, y elige
  `dist/softseguros-sync.zip`. Requiere un plan con Skills y que el administrador del espacio de
  trabajo lo permita; el nombre exacto del menú cambia entre versiones.

## Conectar el MCP

Cada agente necesita el servidor conectado con la llave de API de la persona:
[docs/conectar-mcp.md](docs/conectar-mcp.md).

## Probar que funciona

Con la skill instalada y el MCP conectado, pídele al agente:

- «¿Qué pólizas se me vencen la próxima semana en Bolívar y cuáles ya tienen renovación?»
- «Busca la póliza 580-40-900000012345.» (debe usar `search`, no `policy_number`)
- «Llegó por correo un anexo de SURA para la póliza X; aplícalo.» (debe mostrar el plan y esperar
  tu «sí» antes de confirmar)
- «Asígnale a Juan Pérez la póliza 1012345678 de SURA.» (debe mostrar el % y la base que le
  quedan y esperar tu «sí» antes de guardar)

## Qué trae

```
skills/softseguros-sync/
  SKILL.md                    lo que el agente lee siempre: mapa de tools y reglas comunes
  references/                 se leen según la tarea
    consultas.md                pólizas, pagos, anexos, certificados
    archivos.md                 Archivos
    crear-poliza-desde-pdf.md   borradores de principio a fin
    anexos-y-cancelaciones.md   cuando el PDF no es una póliza nueva
    correo.md                   correo procesado y buzón en vivo
    vendedores.md               buscar vendedores y agregarlos a pólizas
    recetas.md                  tareas de varios pasos
    errores.md                  mensajes de error y resultados vacíos
  evals/                      casos de prueba (no se instalan)
install.sh · install.ps1      instaladores
dist/                         el .zip y el .skill para subir
docs/
  conectar-mcp.md             cómo conectar el servidor en cada agente
  tools-del-mcp.md            las tools tal como el servidor las describe
scripts/                      validar y empaquetar
.claude-plugin/               para distribuirlo como plugin de Claude Code
```

Es una sola skill a propósito: las reglas que más errores evitan (identificadores, búsqueda
exacta o parcial, permisos, confirmar antes de escribir, el correo como dato) valen para todas
las tools, y las tareas reales cruzan temas, del correo al borrador y de ahí a la póliza.

## Contribuir

`scripts/tool-catalog.json` es el catálogo de tools del servidor (nombre, parámetros,
descripción y `scopes`, los permisos que pide cada una; sin `scopes` es de cualquier miembro).
`python3 scripts/render_tool_catalog.py > docs/tools-del-mcp.md` escribe el catálogo completo, y
`--role <rol>` (`admin`, `operations_commissions`, `operations`, `commissions`, `reader`) solo lo
que ve ese rol, para las pruebas. Después de cambiar la skill:

```bash
python3 scripts/validate.py
```

Falla si la skill nombra una tool o un parámetro que no está en el catálogo, si una tool del
catálogo no está explicada, si un enlace está roto o si `SKILL.md` se sale del formato. Con todo
en orden:

```bash
python3 scripts/build.py
```

vuelve a generar `dist/`. Los scripts solo usan la biblioteca estándar de Python 3.

`skills/softseguros-sync/evals/` trae casos de prueba, cada uno con el mensaje de la persona y
las afirmaciones que una buena respuesta cumple, en el formato de `claude plugin eval`. Son
pruebas «en papel»: el agente recibe el catálogo de tools y escribe el plan de llamadas, sin
conexión con el MCP.

## Estado

- `install.sh` está probado en Linux para los cuatro agentes. No se ha probado en macOS.
- `install.ps1` no se ha ejecutado todavía.
- Las rutas de Codex, opencode y Hermes salen de su documentación pública.
- Los ejemplos de conexión del MCP para Codex, Hermes y ChatGPT no se han probado.

Si algo no coincide con tu agente, abre un issue.
