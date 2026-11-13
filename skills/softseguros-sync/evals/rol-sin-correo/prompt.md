---
tags: [softseguros-sync]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write]
---

En esta prueba no hay conexión con el MCP. El archivo tools-del-mcp.md trae las tools tal como el servidor las describe. Responde con el plan: las llamadas que harías, en orden y con sus argumentos exactos, y lo que le dirías a la persona en cada punto en que te detengas. Escribe el plan en plan.md.

Mensaje de la persona:

búscame en el correo de la agencia lo que mandó allianz ayer

Input files: tools-del-mcp.md
