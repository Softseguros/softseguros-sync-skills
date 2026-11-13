---
type: llm
focus: trace
weight: 1
---

Ante un error de confirm_policy_draft (por ejemplo «La póliza cambió…»), el plan vuelve a leer el borrador con get_policy_draft en vez de esperar que el error traiga el plan nuevo (un campo «current»).
