---
tags: [softseguros-sync]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write]
---

En esta prueba no hay conexión con el MCP. El archivo tools-del-mcp.md trae las tools tal como el servidor las describe. Responde con el plan: las llamadas que harías, en orden y con sus argumentos exactos, y lo que le dirías a la persona en cada punto en que te detengas. Escribe el plan en plan.md.

Contexto: llamaste search_policies(policy_number="580-40-900000012345", carrier="Seguros Bolívar") y respondió {"policies": [], "total": 0, "page": 1, "limit": 20, "pages": 0}. La persona dice: «esa póliza sí está, la vi ayer en el sincronizador». ¿Qué haces?

Input files: tools-del-mcp.md
