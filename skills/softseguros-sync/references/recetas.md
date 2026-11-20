# Recetas: tareas de varios pasos

Cada receta da el orden de las llamadas y dónde hay que parar a preguntar. Los argumentos entre
`<…>` salen de la respuesta anterior; nunca se inventan.

## Contenido

- [1. Del correo a la póliza](#1-del-correo-a-la-póliza)
- [2. «Crea la póliza de este PDF»](#2-crea-la-póliza-de-este-pdf)
- [3. Llegó un anexo o una cancelación](#3-llegó-un-anexo-o-una-cancelación)
- [4. Qué vence y qué debe](#4-qué-vence-y-qué-debe)
- [5. Todo sobre un cliente](#5-todo-sobre-un-cliente)
- [6. «¿Llegó el correo de la aseguradora?»](#6-llegó-el-correo-de-la-aseguradora)
- [7. Revisar la bandeja pendiente](#7-revisar-la-bandeja-pendiente)
- [8. Borradores que quedaron a medias](#8-borradores-que-quedaron-a-medias)
- [9. Historia de una póliza](#9-historia-de-una-póliza)
- [10. Asignar un vendedor a las pólizas de un cliente](#10-asignar-un-vendedor-a-las-pólizas-de-un-cliente)

## 1. Del correo a la póliza

«Crea la póliza que mandó SURA esta mañana.»

1. `search_emails(sender="sura", received_from=<hoy>, category="emision")`. Si hay varios,
   muéstralos (remitente, asunto, hora, número detectado) y pregunta cuál.
2. `get_email(<id>)`. Toma el adjunto PDF y su `file_id`.
3. `create_policy_draft_from_file(file_id=<file_id>)`.
4. `get_policy_draft(<draft_id>)` cada 10 a 15 s hasta que salga de `extracting`.
5. Muestra el resumen del borrador. **Para y espera el «sí».**
6. `confirm_policy_draft(<draft_id>, expected_revision=<revision>)`.
7. `get_policy_draft` hasta `created`. Confirma con número, vigencia y tomador.
8. Ofrece, sin hacerlo: vincular el correo a la póliza y marcarlo como gestionado. Si acepta:
   `get_policy(<result.unique_key>)` → `link_email(<email_id>, "policy", <id de la póliza>)` →
   `mark_email_reviewed(<email_id>, "processed")`.

Si el adjunto no tiene `file_id`, o el correo no está entre los procesados, mira «Adjuntos» en
[correo.md](correo.md).

## 2. «Crea la póliza de este PDF»

1. ¿Dónde está el PDF?
   - En Archivos: `search_files(query=<nombre o número>, mime_type="application/pdf")` →
     `create_policy_draft_from_file`.
   - Adjunto al chat y tienes su base64 exacto: `create_policy_draft_from_pdf`.
   - Adjunto al chat y no puedes codificarlo: pide que lo suba en la app (Pólizas › Crear póliza ›
     Desde un PDF) y sigue desde `list_policy_drafts`.
2. Espera la lectura, muestra el resumen, corrige lo que la persona indique con
   `update_policy_draft` y confirma con su «sí».

Detalle de cada paso: [crear-poliza-desde-pdf.md](crear-poliza-desde-pdf.md).

## 3. Llegó un anexo o una cancelación

1. Crea el borrador como en la receta 1 o 2.
2. Al leerlo, `document_class` será `endorsement` o `cancellation`.
3. Sin `parent_policy` (estado `waiting_policy`): explica que su póliza aún no está y las dos
   salidas (esperar o crear primero la póliza). Fin por ahora.
4. Con `parent_policy`: muestra `endorsement_plan.changes` como «hoy → queda» y los avisos.
   Pregunta qué cambios aplicar y, si hay dos modos de prima, cuál.
5. **Para.** Para una cancelación pide que la confirme nombrando la póliza.
6. `confirm_policy_draft(<draft_id>, <revision>, apply_changes=[…], premium_mode=…)`.
7. `get_policy_draft` → `applied_to_policy`. Verifica con `get_policy(<result.unique_key>)` y
   cuéntale cómo quedó.

Detalle: [anexos-y-cancelaciones.md](anexos-y-cancelaciones.md).

## 4. Qué vence y qué debe

«¿Qué se me vence la próxima semana y cuánto deben esos clientes?»

1. `search_policies(end_date_from=<lunes>, end_date_to=<domingo>, status="active")`. Si `total`
   supera el `limit`, trae las páginas que falten o pregunta si acota por aseguradora.
2. Para cada póliza (o para las que la persona elija, si son muchas):
   `search_payments(policy_number=<policy_number exacto>)` y suma `balance`.
3. Una tabla: póliza, tomador, aseguradora, vence, prima, saldo pendiente, días de mora.
4. Aclara qué aseguradoras no reportan cartera, para que un saldo vacío no se lea como cero.

Son muchas llamadas: con más de unas 15 pólizas, ofrece primero la lista de vencimientos y trae la
cartera solo de las que le interesen.

## 5. Todo sobre un cliente

«Muéstrame todo lo de la empresa con NIT 900123456.»

1. `search_policies(search="900123456")`: como tomador y como asegurado.
2. `search_certificates(search="900123456")`: si está asegurado dentro de colectivas.
3. `search_payments(search="900123456")`: su cartera.
4. `search_files(query=<nombre o NIT>)`: documentos sueltos.
5. `search_emails(query=<nombre>)`, si la persona tiene acceso al correo.
6. Los vendedores de cada póliza vienen en `commission_sellers` de las filas del paso 1.

Presenta por secciones (pólizas vigentes, por vencer, cartera, documentos) y deja lo histórico en
una línea («además, 6 vigencias anteriores»). Los datos de contacto del cliente (teléfonos,
correos, dirección) no se consultan desde este MCP: están en la app, en Contactos, o en el CRM.

## 6. «¿Llegó el correo de la aseguradora?»

1. `list_mailboxes()` y mira `last_sync_at`.
2. `search_emails(sender=<aseguradora o dominio>, received_from=<fecha>)`.
3. Si no aparece: `search_mailbox(mailbox_id=<buzón>, sender=…, received_from=…)` en cada buzón
   probable. Dilo: «no está entre los procesados; busqué directamente en el buzón».
4. Si aparece en vivo: `get_thread` para leerlo y ver `attachment_names`.
5. Responde con qué encontraste y dónde. Si no está en ninguno, di en qué buzones y fechas
   buscaste; puede estar en un buzón al que la persona no tiene acceso o en spam.

## 7. Revisar la bandeja pendiente

«¿Qué correos tengo sin revisar?»

1. `search_emails(status="pending_review")`. Di el `total`.
2. Agrupa por `category` y aseguradora: tantas emisiones, tantos anexos, tantas cancelaciones.
3. Ofrece seguir uno por uno: leerlo, crear el borrador de su PDF, vincularlo, marcarlo.
4. No marques ninguno como revisado en bloque sin que la persona lo pida correo por correo o diga
   exactamente cuáles.

## 8. Borradores que quedaron a medias

«¿Qué borradores tengo pendientes?»

1. `list_policy_drafts()` (abiertos). Para cada uno: archivo, aseguradora, póliza, tomador, estado,
   cuántos errores y avisos.
2. Tradúcelos: «listo para confirmar», «le falta resolver 2 puntos», «esperando su póliza»,
   «leyendo».
3. Para retomar uno: `get_policy_draft` y sigue desde el paso de mostrarlo.
4. Los que fallaron: `list_policy_drafts(status="failed")` y mira `error` en cada uno.

## 9. Historia de una póliza

«¿Qué ha pasado con la póliza 123456?»

1. `search_policies(search="123456")`: todas sus vigencias. Ordénalas por `start_date`.
2. Sigue `previous_cycle_unique_key` / `next_cycle_unique_key` con `get_policy` si falta alguna.
3. `search_endorsements(policy_number=<número exacto>)`: sus anexos; mira también `endorsements`
   dentro de la póliza.
4. `search_payments(policy_number=<número exacto>)`: su cartera.
5. Cuenta la historia en orden: emisión, renovaciones, anexos (con lo que cambiaron), cancelación
   si la hubo, saldo pendiente. Señala los cambios aplicados desde un PDF
   (`manual_override_fields`).

## 10. Asignar un vendedor a las pólizas de un cliente

«Ponle a Ana Gómez todas las pólizas vigentes de Transportes Andinos.»

1. `search_policies(search=<NIT o nombre>, status="active")`. Muestra cuántas son y cuáles
   (número, aseguradora, producto, vendedores actuales de `commission_sellers`).
2. `search_sellers(query="ana gomez")`. Si hay más de una, pregunta cuál.
3. `preview_policy_sellers(unique_key=<una de ellas>, seller_ids=[<seller_id>])`, y otra de una
   aseguradora o producto distinto si las hay: el % puede cambiar entre pólizas.
4. Muestra el resumen: cuántas pólizas, a quién se agrega, el % y la base de ejemplo, cuáles ya la
   tienen. **Para y espera el «sí».**
5. `add_policy_sellers(unique_keys=[<las pólizas>], seller_ids=[<seller_id>])`, hasta 50 por llamada.
6. Informa con `updated`, `already_had` y `skipped_conflict`. Las de `skipped_conflict` no se
   tocaron: léelas con `get_policy_sellers` y pregunta qué hacer.

Detalle en [vendedores.md](vendedores.md).
