---
tags: [softseguros-sync]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write]
---

En esta prueba no hay conexión con el MCP. El archivo tools-del-mcp.md trae las tools tal como el servidor las describe. Responde con el plan: las llamadas que harías, en orden y con sus argumentos exactos, y lo que le dirías a la persona en cada punto en que te detengas. Escribe el plan en plan.md.

Contexto: creaste un borrador (draft_id «6734a1f0c2», revision 3) desde un PDF de HDI, se lo mostraste a la persona, respondió «sí, créala» y llamaste confirm_policy_draft(draft_id="6734a1f0c2", expected_revision=3). La tool respondió:

Error executing tool confirm_policy_draft: Esta póliza ya existe. Elige si vincular el PDF o completar los datos que le faltan

¿Qué haces ahora?

Input files: tools-del-mcp.md
