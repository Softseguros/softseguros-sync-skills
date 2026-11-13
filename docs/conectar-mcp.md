# Conectar el MCP del Sincronizador

La skill explica cómo usar las tools; no las trae. Cada agente necesita además el servidor MCP
conectado.

- **URL:** `https://sync-api.softseguros.com/mcp`
- **Autenticación:** una llave de API personal (`Authorization: Bearer <llave>`) o OAuth.
- **Llave de API:** en la app, Ajustes › General › Llaves de API. Se muestra una sola vez. El
  asistente actúa con el rol de la persona dueña de la llave.
- **OAuth:** la app muestra el Client ID en Ajustes › General › MCP.

Guarda la llave en una variable de entorno en vez de escribirla en un archivo que se comparta:

```bash
export SOFTSEGUROS_SYNC_API_KEY="pega-aquí-tu-llave"
```

Los ejemplos de Claude Code y opencode siguen el formato que usa hoy el proyecto. Los de Codex,
Hermes y ChatGPT no se pudieron probar al preparar este paquete: confírmalos con la documentación
de cada agente si algo no coincide.

## Claude Code

```bash
claude mcp add --transport http insurance-sync https://sync-api.softseguros.com/mcp --header "Authorization: Bearer $SOFTSEGUROS_SYNC_API_KEY"
```

Comprueba con `/mcp` dentro de Claude Code: debe aparecer `insurance-sync` conectado.

## claude.ai y Claude Desktop

Ajustes › Conectores › Agregar conector personalizado. Pega la URL y, en opciones avanzadas, el
Client ID de OAuth que muestra la app del Sincronizador. Al conectar se abre el inicio de sesión
de Softseguros.

## Codex CLI

En `~/.codex/config.toml`:

```toml
[mcp_servers.insurance-sync]
url = "https://sync-api.softseguros.com/mcp"
bearer_token_env_var = "SOFTSEGUROS_SYNC_API_KEY"
```

## ChatGPT

En ChatGPT los servidores MCP se agregan como conector o app personalizada (modo desarrollador,
según el plan y lo que permita el administrador del espacio de trabajo). Usa la misma URL y OAuth
con el Client ID de la app.

## opencode

En `opencode.json` (del proyecto o `~/.config/opencode/opencode.json`):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "insurance-sync": {
      "type": "remote",
      "url": "https://sync-api.softseguros.com/mcp",
      "headers": { "Authorization": "Bearer {env:SOFTSEGUROS_SYNC_API_KEY}" }
    }
  }
}
```

## Hermes Agent

En `~/.hermes/config.yaml`:

```yaml
mcp_servers:
  insurance-sync:
    url: "https://sync-api.softseguros.com/mcp"
    headers:
      Authorization: "Bearer TU_LLAVE"
```

## Otros clientes (Cursor y similares)

```json
{
  "mcpServers": {
    "insurance-sync": {
      "url": "https://sync-api.softseguros.com/mcp",
      "headers": { "Authorization": "Bearer TU_LLAVE" }
    }
  }
}
```

## El otro servidor: CRM SoftSeguros

`https://sync-api.softseguros.com/mcp/softseguros` es un servidor distinto (el CRM). Se conecta
aparte, con el nombre `softseguros-crm`, y trae sus propias instrucciones. Esta skill no lo cubre;
solo explica cómo distinguirlos.

## Comprobar que quedó

Pídele al agente: «¿Cuántas pólizas tengo en el Sincronizador?». Debe llamar `search_policies` y
responder con un total. Si no ve ninguna tool, la llave no es válida o se revocó. Si ve las de
consulta pero no las de correo ni las de borradores, es el rol de la persona, no un fallo.
