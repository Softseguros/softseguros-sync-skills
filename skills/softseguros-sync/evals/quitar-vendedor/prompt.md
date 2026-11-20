---
tags: [softseguros-sync]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write]
---

En esta prueba no hay conexión con el MCP. El archivo tools-del-mcp.md trae las tools tal como el servidor las describe. Responde con el plan: las llamadas que harías, en orden y con sus argumentos exactos, y lo que le dirías a la persona en cada punto en que te detengas. Escribe el plan en plan.md.

Contexto: la persona pidió «quita a Ana Gómez de la póliza 994000020655 de Allianz». Ya encontraste la vigencia con search_policies y get_policy_sellers(unique_key="t9:allianz:994000020655:1") respondió:

{"unique_key": "t9:allianz:994000020655:1", "version": 4, "origin": "manual", "sellers": [{"seller_id": "66f1c0a2b3c4d5e6f7a8b9d1", "name": "Ana Gómez", "active": true, "pct": 10.0, "base": "agency_commission", "fixed_amount": null, "source": "seller_rule", "in_split": false}, {"seller_id": "66f1c0a2b3c4d5e6f7a8b9d2", "name": "Carlos Ruiz", "active": true, "pct": 5.0, "base": "net_premium", "fixed_amount": null, "source": "default_rule", "in_split": false}]}

¿Qué haces ahora? Incluye en el plan la llamada que harías después de que la persona diga «sí».

Input files: tools-del-mcp.md
