---
tags: [softseguros-sync]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write]
---

En esta prueba no hay conexión con el MCP. El archivo tools-del-mcp.md trae las tools tal como el servidor las describe. Responde con el plan: las llamadas que harías, en orden y con sus argumentos exactos, y lo que le dirías a la persona en cada punto en que te detengas. Escribe el plan en plan.md.

Contexto: la persona pidió «ponle a Carlos la póliza 580-40-900000012345». Ya encontraste la póliza con search_policies (unique_key «t9:bolivar:900000012345:40», vigente). search_sellers(query="carlos") respondió:

{"sellers": [{"seller_id": "66f1c0a2b3c4d5e6f7a8b9c0", "name": "Carlos Ruiz", "active": true, "default_commission": null}, {"seller_id": "66f1c0a2b3c4d5e6f7a8b9c1", "name": "Carlos Mejía", "active": true, "default_commission": {"pct": 8.0, "base": "agency_commission"}}, {"seller_id": "66f1c0a2b3c4d5e6f7a8b9c2", "name": "Carlos Ruiz", "active": false, "default_commission": null}], "total": 3}

¿Qué haces ahora?

Input files: tools-del-mcp.md
