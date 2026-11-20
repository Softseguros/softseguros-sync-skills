# Errores y resultados vacíos

Cuando una tool falla llega solo el texto del error
(`Error executing tool <nombre>: <mensaje>`), sin más datos. Reconoce el caso por el mensaje y, si
hace falta el detalle (el borrador actual, la póliza que ya existe), vuelve a leer el objeto.

## Contenido

- [Una tool no aparece](#una-tool-no-aparece)
- [Mensajes de error](#mensajes-de-error)
- [Resultados vacíos](#resultados-vacíos)
- [Qué decirle a la persona](#qué-decirle-a-la-persona)

## Una tool no aparece

El catálogo se arma según el rol de la persona. Si no ves las tools de borradores ni las de correo,
su rol no opera pólizas (lo hacen Administrador, Operación y Operación y comisiones). Si no ves
`add_policy_sellers`, su rol no asigna vendedores (Consulta). No es un fallo de conexión.
Explícalo y remite a un administrador de la agencia (Ajustes › Miembros).

Si no aparece **ninguna** tool, la credencial no es válida: mira «Permisos y autenticación».

## Mensajes de error

### Permisos y autenticación

| El error dice… | Qué pasa | Qué hacer |
| --- | --- | --- |
| «Tu rol no permite usar esta herramienta del asistente» | El rol no incluye esa tool. | Explicarlo; lo cambia un administrador. No buscar otro camino. |
| «No tienes permiso para crear pólizas desde un PDF» | Lo mismo, para borradores. | Igual. |
| «Esta herramienta es para las personas de la agencia» | El MCP no se conectó con la llave de una persona. | Crear una llave de API personal en Ajustes › General y reconectar. |
| «Missing Authorization header», un 401, o no lista tools | Falta la llave, venció o se revocó. | Reconectar el MCP: llave nueva en Ajustes › General, o volver a iniciar sesión si es OAuth. |

Un cambio de rol aplica en la siguiente llamada: si a la persona le acaban de dar el permiso, basta
reintentar (o reconectar para que el catálogo se actualice).

### Consultas

| El error dice… | Qué hacer |
| --- | --- |
| «Policy not found», «Payment not found», «Endorsement not found», «Certificate not found» | El `unique_key` no existe en esta agencia. Casi siempre se armó a mano o viene de otra conversación: búscalo de nuevo y copia el de la respuesta. |
| «Invalid date filter '…': expected YYYY-MM-DD» | Corrige el formato y repite. No vale «2026-7-3» ni fecha con hora. |
| «Policy PDF is not linked (status=…)» | Esa póliza no tiene PDF. El `status` del mensaje dice por qué (tabla en [consultas.md](consultas.md)). Prueba `search_files`. |
| «Policy PDF file not found in storage» | La póliza apunta a un archivo que ya no está. Sugiere reportarlo a soporte. |
| «File not found» | El `file_id` no existe, o es un archivo de un buzón que la persona no lee. No se distingue; no insistas. |
| Error de validación de argumentos (por ejemplo un `status` que no es de la lista) | Usa un valor de la lista de la referencia. Los estados van en inglés y minúsculas. |

### Borradores

| El error dice… | Qué hacer |
| --- | --- |
| «No encontramos ese borrador de póliza» | `draft_id` equivocado. `list_policy_drafts`. |
| «El borrador cambió mientras lo editabas…» | La `revision` que mandaste es vieja (alguien lo editó, o se volvió a validar). `get_policy_draft`, revisa qué cambió, muéstraselo a la persona y repite con la `revision` nueva. |
| «Este borrador ya no se puede modificar» | Ya está creándose, creado, descartado o falló. `get_policy_draft` para ver su estado. |
| Un campo o una ruta no válida | La ruta de `changes` no existe en el formato o el valor no tiene el tipo esperado (fecha `YYYY-MM-DD`, dinero como número). Formato en [crear-poliza-desde-pdf.md](crear-poliza-desde-pdf.md). |
| «El borrador tiene errores que impiden crear la póliza» | `get_policy_draft` y resuelve `validation.errors`. En un anexo también puede ser una prima negativa o un modo de prima no disponible. |
| «Esta póliza ya existe. Elige si vincular el PDF o completar los datos que le faltan» | `get_policy_draft`, muestra `duplicates[0]` y pregunta: `link_pdf`, `fill_missing` u otra vigencia. |
| «La póliza cambió mientras revisabas el anexo…» | No se aplicó nada. `get_policy_draft`, muestra el plan nuevo y confirma solo si la persona sigue de acuerdo. |
| «El archivo debe ser un PDF» | Solo PDF. Una foto o un Word no sirven. |
| «The PDF exceeds 10 MB» | Por el MCP el tope es 10 MB; en la app, 20 MB. |
| «content_base64 is not valid base64» | El base64 llegó dañado o incompleto. No lo «arregles» a mano: usa `create_policy_draft_from_file` con el archivo en Archivos. |
| «premium_mode must be "add" or "replace"», «apply_changes must be among…» | Usa los valores exactos de [anexos-y-cancelaciones.md](anexos-y-cancelaciones.md). |

Una regla para todos: tras un error de borrador, lee el borrador otra vez antes de volver a
escribir. Reintentar la confirmación con la misma `revision` no duplica nada, pero reintentar sin
mirar oculta el motivo del rechazo.

### Vendedores

| El error dice… | Qué hacer |
| --- | --- |
| «No tienes permiso para modificar comisiones» | El rol no asigna vendedores (Consulta). Explícalo; lo cambia un administrador. |
| «No encontramos esa póliza» | El `unique_key` no es de esta agencia o se armó a mano. Búscala de nuevo con `search_policies`. |
| «El vendedor indicado no existe» / «No encontramos ese vendedor» | `seller_id` equivocado. Usa uno de `search_sellers`. |
| «El vendedor está inactivo» | No se guardó nada. Quita ese vendedor del pedido y dile a la persona que se reactiva en Comisiones › Vendedores. |
| «Hay demasiados elementos en la solicitud» | Más de 50 pólizas o 10 vendedores. Divide el pedido o hazlo en la app. |
| «… must name at least one», «… must be a list» | Falta la lista de pólizas o de vendedores: pásala como lista, aunque sea de uno. |

Un `skipped_conflict` en la respuesta no es un error: esa póliza no se tocó. Léela con
`get_policy_sellers` y cuéntale a la persona qué tiene ahora antes de volver a intentar.

### Correo

| El error dice… | Qué hacer |
| --- | --- |
| «Email message not found» | El `email_id` no existe o es de un buzón que la persona no lee. |
| «Email account not found» | `mailbox_id` equivocado o buzón sin acceso. Usa los de `list_mailboxes`. |
| «Este buzón todavía no terminó de conectarse» | Falta terminar la conexión en Ajustes › Integraciones › Correo. |
| «Este buzón no se puede leer en vivo» | Es POP3. Solo se puede usar el correo procesado. |
| «El proveedor de correo tardó demasiado en responder…» | Pasaron 30 segundos. Acota con fechas o remitente y reintenta una vez. |
| «Ese correo no tiene un adjunto con ese nombre» | Copia el nombre exacto de `attachment_names`. |
| «El adjunto supera los 10 MB» / «The attachment exceeds 10 MB» | No se puede traer por el MCP. La persona lo descarga desde su correo. |
| Un error del proveedor (Gmail, Outlook, IMAP) | Puede haber vencido la conexión del buzón. Sugiere «Probar conexión» en Ajustes › Integraciones › Correo. |

## Resultados vacíos

Antes de decir «no hay», descarta estas causas, en este orden:

1. **Filtro exacto con un valor aproximado.** `policy_number`, `certificate_number`, `carrier` y el
   `status` de pagos son exactos. Repite con `search` y sin `carrier`.
2. **Slug de aseguradora equivocado.** Busca sin `carrier` y mira `carrier_slug`.
3. **Varias palabras en `search`.** Es un solo texto: «juan perez sura» no coincide con nada. Usa
   el dato más distintivo (documento, número, placa).
4. **El número viene con formato.** Quita puntos, espacios y ceros a la izquierda, o busca solo el
   tramo final.
5. **Rango de fechas.** Verifica año y que `from` no sea posterior a `to`.
6. **Estado.** Una póliza recién renovada no está `active`: puede ser `pre_renewal`. Quita `status`.
7. **El dato no está en el Sincronizador.** La aseguradora no tiene bot, la conexión no ha corrido
   o esa aseguradora no reporta ese dato (no todas traen cartera, anexos o certificados).
8. **Correo:** no trae PDF, es anterior a la sincronización o está en un buzón sin acceso. Prueba
   el buzón en vivo.

Si después de esto sigue vacío, dilo con precisión: «El Sincronizador no tiene pólizas con ese
número ni con ese documento», no «la póliza no existe».

## Qué decirle a la persona

- Traduce el error a lo que pasa y a lo que puede hacer. No pegues el mensaje técnico.
- Si es un permiso, dilo como tal y di quién lo cambia.
- Si es un límite del MCP, di dónde se hace en la app.
- Si parece un fallo del servidor (error inesperado, tiempo agotado repetido), dilo sin adornos y
  sugiere reintentar más tarde o escribir a soporte de Softseguros. No inventes una causa.
