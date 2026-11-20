---
tags: [softseguros-sync]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write]
---

En esta prueba no hay conexión con el MCP. El archivo tools-del-mcp.md trae las tools tal como el servidor las describe. Responde con el plan: las llamadas que harías, en orden y con sus argumentos exactos, y lo que le dirías a la persona en cada punto en que te detengas. Escribe el plan en plan.md.

Contexto: la persona pidió «sube a Juan Pérez al 15 % en la póliza 1012345678 de SURA». get_policy_sellers(unique_key="t9:sura:1012345678:40") respondió:

{"unique_key": "t9:sura:1012345678:40", "version": 7, "origin": "manual", "sellers": [{"seller_id": "66f1c0a2b3c4d5e6f7a8b9e1", "name": "Juan Pérez", "active": true, "pct": 10.0, "base": "agency_commission", "fixed_amount": null, "source": "manual", "in_split": true}, {"seller_id": "66f1c0a2b3c4d5e6f7a8b9e2", "name": "Laura Díaz", "active": true, "pct": 10.0, "base": "agency_commission", "fixed_amount": null, "source": "manual", "in_split": true}]}

¿Qué haces ahora?

Input files: tools-del-mcp.md
