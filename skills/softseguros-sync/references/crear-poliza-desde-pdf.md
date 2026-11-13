# Crear una póliza desde un PDF (borradores)

Las siete tools de borradores son para los roles que operan pólizas (Administrador, Operación,
Operación y comisiones), incluso para leer. Si no están en tu catálogo, el rol de la persona no las incluye.

## Contenido

- [La idea en una línea](#la-idea-en-una-línea)
- [Paso 1: crear el borrador](#paso-1-crear-el-borrador)
- [Paso 2: esperar la lectura](#paso-2-esperar-la-lectura)
- [Paso 3: leer el borrador](#paso-3-leer-el-borrador)
- [Paso 4: mostrarlo a la persona](#paso-4-mostrarlo-a-la-persona)
- [Paso 5: corregir](#paso-5-corregir)
- [Paso 6: confirmar](#paso-6-confirmar)
- [Paso 7: verificar que se creó](#paso-7-verificar-que-se-creó)
- [Cuando la póliza ya existe](#cuando-la-póliza-ya-existe)
- [Validaciones](#validaciones)
- [Estados de un borrador](#estados-de-un-borrador)
- [El formato de `values`](#el-formato-de-values)
- [Lo que no se puede desde el MCP](#lo-que-no-se-puede-desde-el-mcp)

## La idea en una línea

Un PDF se convierte en un **borrador** con los datos leídos; la persona lo revisa; solo
`confirm_policy_draft` crea la póliza. Mientras no se confirme, nada existe en la cartera.

```
crear borrador → esperar lectura → leer → mostrar a la persona → (corregir) → confirmar → verificar
```

## Paso 1: crear el borrador

Elige la entrada por dónde está el PDF. El orden de la lista es el orden de preferencia.

| Dónde está el PDF | Tool | Por qué |
| --- | --- | --- |
| En Archivos (`search_files`) o en un correo procesado (`get_email` → `attachments[].file_id`) | `create_policy_draft_from_file(file_id)` | No mueve el contenido: solo pasa un id. Es la más segura y la más barata. |
| Solo en la conversación, y puedes obtener su base64 exacto | `create_policy_draft_from_pdf(filename, content_base64)` | Sube el PDF a Archivos y lo lee. Máximo 10 MB. |
| En Archivos, y además ya lo leíste tú con certeza | `create_policy_draft(file_id, values)` | No usa el lector del servidor: tú pasas los valores. Úsala cuando la lectura automática falló o no está configurada. |

Sobre el base64: el contenido tiene que ser el archivo exacto, byte a byte. Un modelo no puede
«transcribir» un PDF a base64 de memoria ni copiar megas de texto sin dañarlo. Usa
`create_policy_draft_from_pdf` solo si tu entorno te entrega el base64 del archivo (por ejemplo,
viene de `get_mailbox_attachment` y el adjunto es pequeño). Si el PDF solo está adjunto al chat y
no tienes cómo codificarlo, pide a la persona que lo suba en la app (Pólizas › Crear póliza › Desde
un PDF, o Archivos) y sigue con `create_policy_draft_from_file`.

`create_policy_draft` también necesita `file_id`: el PDF debe estar en Archivos aunque los valores
los pongas tú.

Parámetros opcionales de las tres:

- `carrier_slug`: normalmente sobra, la aseguradora se detecta por su NIT o su nombre. Pásalo si la
  persona la dijo o si el borrador vuelve con `CARRIER_REQUIRED`.
- `connection_id`: solo cuando la agencia tiene varias conexiones de esa aseguradora. El borrador
  trae `connection_options` con las posibles; pregunta a la persona cuál.
- `password_hint` (solo en `_from_pdf`): la contraseña del PDF. Suele ser el documento del tomador.

Crear un borrador no compromete nada, así que hazlo en cuanto la persona pida crear la póliza.

## Paso 2: esperar la lectura

`_from_file` y `_from_pdf` devuelven el borrador en `extracting`: el servidor lee el PDF en segundo
plano y tarda entre medio minuto y unos minutos. Llama `get_policy_draft(draft_id)` cada 10 a 15
segundos hasta que el estado cambie, y avísale a la persona que la lectura está en curso. Si pasan
unos cinco minutos sin cambio, deja de consultar, dale el estado y ofrece revisar más tarde con
`list_policy_drafts`: el servidor reintenta solo y marca el borrador `failed` si no lo logra.

`create_policy_draft` (con `values`) vuelve ya validado, sin espera.

## Paso 3: leer el borrador

`get_policy_draft` devuelve, entre otros:

| Campo | Para qué |
| --- | --- |
| `status`, `revision` | El estado y la versión. `revision` se manda en cada cambio y en la confirmación. |
| `values` | Los datos de la póliza (formato abajo). |
| `validation.errors` | Impiden crear. Hay que resolverlos todos, salvo `DUPLICATE_POLICY`, que se resuelve al confirmar. |
| `validation.warnings`, `validation.infos` | No impiden crear, pero la persona debe verlos. |
| `low_confidence_fields` | Rutas de los datos leídos con poca certeza. Pídele a la persona que los verifique contra el PDF. |
| `carrier_slug`, `carrier_name`, `carrier_source` | La aseguradora y cómo se determinó. |
| `tenant_carrier_id`, `connection_options`, `will_create_manual_connection` | La conexión donde quedará. Si no hay ninguna, se crea una «Manual». |
| `parties_preview` | Si el tomador (y el asegurado) quedará como contacto o empresa, y si ya existe (`exists`, `entity_id`). |
| `duplicates` | Pólizas que ya existen con ese número. |
| `product_mapped`, `mapped_products` | Si el producto está en la configuración de sincronización con SoftSeguros. |
| `key_exactness` | `provisional` significa que el bot, cuando traiga esa póliza, la unirá con esta. |
| `predicted_status` | El estado con que nacería la póliza (por ejemplo `pre_renewal` si empieza en el futuro). |
| `document_class`, `parent_policy`, `endorsement_plan` | Qué es el PDF. Si no es `policy`, lee [anexos-y-cancelaciones.md](anexos-y-cancelaciones.md). |
| `error` | Por qué falló, cuando `status` es `failed`. |
| `result` | Tras confirmar: el `unique_key` de la póliza creada o modificada. |

## Paso 4: mostrarlo a la persona

Antes de confirmar, presenta un resumen que le permita decidir sin abrir el PDF:

```
Borrador de póliza · <aseguradora> · <producto>
Póliza:     <policy_number>   (<nueva | renovación N>)
Vigencia:   <start_date> a <end_date>
Tomador:    <nombre> · <tipo y documento>   → se crea como <contacto | empresa> / ya existe
Asegurado:  <nombre> (si es otro)
Riesgo:     <placa y vehículo | dirección | persona> · valor asegurado <…>
Prima:      neta <…> + IVA <…> + gastos <…> = total <…>
Conexión:   <etiqueta>  (o «se creará una conexión Manual»)

Para revisar contra el PDF: <low_confidence_fields en palabras>
Avisos: <warnings e infos en palabras>
Falta resolver: <errors en palabras>

¿La creo así, o corrijo algo?
```

Di los nombres de los campos en español («prima neta», no `premium.net`). No ocultes un aviso
porque parezca menor: `PREMIUM_MISMATCH` o `NIT_DV_MISMATCH` suelen ser errores de lectura.

## Paso 5: corregir

`update_policy_draft(draft_id, expected_revision, changes)`.

- `changes` usa rutas con puntos sobre `values`: `{"premium.net": 2450000,
  "holder.emails": ["ana@empresa.example"], "risks.0.vehicle.plate": "JKL123", "product_name": "AUTOS PLUS"}`.
- Fechas `YYYY-MM-DD`, dinero como número sin separadores, el NIT sin dígito de verificación (va
  en `holder.verification_digit`).
- Para vaciar un dato manda `null`. Una ruta que no existe en el formato se rechaza.
- La respuesta es el borrador revalidado con una `revision` nueva: úsala en la siguiente llamada.
- `carrier_slug` y `connection_id` cambian la aseguradora o la conexión; `document_class` corrige
  qué es el PDF.
- `PRODUCT_NOT_MAPPED`: ofrece los nombres de `mapped_products` y, si la persona elige uno, cambia
  `product_name`. Si prefiere el nombre del PDF, se puede crear igual: es un aviso.

Solo se pueden editar borradores en `ready_for_review`, `needs_review` o `waiting_policy`.

## Paso 6: confirmar

Solo con el «sí» explícito de la persona sobre lo que le mostraste en este turno.

`confirm_policy_draft(draft_id, expected_revision)`: la póliza entra por el mismo camino que una
traída por un bot: se crea o actualiza el contacto o la empresa del tomador y la póliza se envía a
SoftSeguros si la agencia tiene esa integración configurada. Devuelve el borrador en `ingesting`.

Si el borrador tiene errores, la confirmación se rechaza con «El borrador tiene errores que impiden
crear la póliza»: vuelve a `get_policy_draft`, lee `validation.errors` y resuélvelos con la persona.

Reintentar la confirmación con la misma `revision` no crea nada dos veces.

## Paso 7: verificar que se creó

Consulta `get_policy_draft` cada 10 segundos hasta:

- `created`: `result.unique_key` es la póliza nueva. Confírmalo a la persona con número, vigencia y
  tomador; puedes leerla con `get_policy`.
- `needs_review` otra vez, con el aviso de que la póliza no se creó: el procesamiento falló.
  Muéstrale el motivo y no reintentes sin que lo pida.

## Cuando la póliza ya existe

Si `duplicates` no está vacío (o la confirmación responde «Esta póliza ya existe. Elige si vincular
el PDF o completar los datos que le faltan»), la póliza ya está en la cartera, casi siempre porque
el bot la trajo. No se crea otra. Muéstrale a la persona la existente (`duplicates[0]`: número,
estado, inicio de vigencia, si ya tiene PDF) y ofrece:

| Opción | `duplicate_resolution` | Efecto |
| --- | --- | --- |
| Solo guardar el PDF en esa póliza | `"link_pdf"` | Vincula el PDF. No cambia datos. |
| Guardar el PDF y completar lo que le falta | `"fill_missing"` | Llena únicamente campos vacíos de la póliza con los del PDF; nunca sobrescribe. `fill_fields` limita a los de `duplicates[0].fillable_fields` que la persona eligió (omítelo para todos). |
| Es otra vigencia | ninguna | No es duplicado: corrige `start_date` / `end_date` con `update_policy_draft` y vuelve a validar. |

El borrador termina en `duplicate_linked` y `result.unique_key` es la póliza existente.

Una renovación (`values.term.kind = "renewal"`) solo es duplicado de la misma vigencia; cualquier
otro documento coincide con la póliza de ese número en cualquier vigencia.

## Validaciones

Vienen en `validation` con `code`, `message` (en español, listo para mostrar) y `field`.

**Errores (impiden crear)**

| Código | Qué hacer |
| --- | --- |
| `CARRIER_REQUIRED` | Pregunta la aseguradora y pásala en `carrier_slug`. |
| `POLICY_NUMBER_REQUIRED`, `START_DATE_REQUIRED`, `END_DATE_REQUIRED` | Pide el dato y corrígelo. |
| `END_BEFORE_START` | Una de las dos fechas se leyó mal: confírmalas con la persona. |
| `HOLDER_DOCUMENT_REQUIRED`, `HOLDER_NAME_REQUIRED` | Pide el dato del tomador. |
| `DUPLICATE_POLICY` | Ver «Cuando la póliza ya existe». |
| `IS_OTHER_DOCUMENT`, `PARENT_POLICY_MISSING` | El PDF no es una póliza. Ver [anexos-y-cancelaciones.md](anexos-y-cancelaciones.md). |

**Avisos (se puede crear; muéstralos)**

| Código | Significado |
| --- | --- |
| `LOW_CONFIDENCE` | Un dato se leyó con poca certeza (también está en `low_confidence_fields`). |
| `PREMIUM_MISMATCH` | Neta + IVA + gastos no da el total (más de 1 % de diferencia). |
| `NIT_DV_MISMATCH` | El dígito de verificación no corresponde al NIT. |
| `PRODUCT_NOT_MAPPED` | El producto no está en la configuración de SoftSeguros de esa conexión. |
| `PROVISIONAL_KEY` | Al PDF le faltan datos con los que el bot identifica la póliza; se unirán cuando el bot la traiga. |
| `MANUAL_CONNECTION` | La agencia no tiene conexión con esa aseguradora: se creará una «Manual». |

**Informativos**: `FUTURE_START` (la póliza empieza en el futuro y nacerá como renovación que aún
no empieza).

## Estados de un borrador

| `status` | Significado | Siguiente paso |
| --- | --- | --- |
| `extracting` | Leyendo el PDF | Esperar y consultar. |
| `ready_for_review` | Leído, sin errores | Mostrar y confirmar. |
| `needs_review` | Leído, con errores o avisos por resolver | Mostrar, corregir, confirmar. |
| `waiting_policy` | Es un anexo o una cancelación y su póliza aún no está | Ver anexos. Se reanuda solo cuando llega la póliza. |
| `ingesting` | Confirmado, creando la póliza | Esperar y consultar. |
| `created` | Póliza creada | `result.unique_key`. |
| `duplicate_linked` | PDF vinculado a una póliza existente | `result.unique_key`. |
| `applied_to_policy` | Anexo o cancelación aplicada a su póliza | `result.unique_key`. |
| `failed` | No se pudo leer | Mira `error`. |
| `discarded` | Descartado en la app | Nada. |

`list_policy_drafts()` trae los abiertos (`extracting`, `ready_for_review`, `needs_review`,
`waiting_policy`, `ingesting`). Para otros estados usa `status` con valores separados por coma, por
ejemplo `status="created,applied_to_policy"`.

Motivos frecuentes de `failed`:

| `error.code` | Qué hacer |
| --- | --- |
| `PDF_PASSWORD_REQUIRED` | Pide la contraseña (suele ser el documento del tomador) y crea un borrador nuevo con `create_policy_draft_from_pdf` y `password_hint`, o pídele que lo reintente en la app. |
| `EXTRACTION_NOT_CONFIGURED` | La lectura automática no está disponible. Si puedes leer el PDF, usa `create_policy_draft` con `values`. |
| `EXTRACT_ERROR`, `EXTRACT_INVALID_OUTPUT`, `EXTRACTION_STUCK` | La lectura falló. Ofrece «Volver a extraer» en la app o `create_policy_draft` con `values`. |

## El formato de `values`

Lo usan `create_policy_draft` (entero) y `update_policy_draft` (por rutas). Es estricto: una clave
que no esté aquí se rechaza. Obligatorios para crear: `policy_number`, `start_date`, `end_date`,
el nombre y el documento del tomador.

```json
{
  "policy_number": "1012345678",
  "policy_type": "individual",
  "product_name": "AUTOS PLUS",
  "product_code": "250",
  "line_of_business": "Automóviles",
  "section_code": "40",
  "certificate_number": null,
  "application_number": null,
  "contract_id": null,
  "issue_date": "2026-09-28",
  "issue_city": "Bogotá",
  "office": null,
  "start_date": "2026-10-03",
  "end_date": "2027-10-03",
  "cancellation_date": null,
  "source_status": null,
  "currency": "COP",
  "term": { "kind": "renewal", "number": 2, "previous_policy_number": null },
  "intermediary": { "name": "…", "code": "…", "participation_pct": 100 },
  "holder": {
    "kind": "company",
    "document_type": "NIT",
    "document": "900123456",
    "verification_digit": "7",
    "business_name": "Empresa de Ejemplo SAS",
    "emails": ["contabilidad@empresa.example"],
    "phones": [{ "kind": "mobile", "value": "3001234567" }],
    "address": "…", "city": "…", "department": "…",
    "legal_representative": { "name": "…", "document_type": "CC", "document": "…" }
  },
  "insured": { "kind": "person", "document_type": "CC", "document": "1012345678",
               "first_name": "Ana", "last_name": "Pérez Gómez", "birth_date": "1988-04-12" },
  "beneficiaries": [
    { "party": { "document_type": "NIT", "document": "800123456", "business_name": "Banco …" },
      "percentage": 100, "onerous": true }
  ],
  "risks": [
    { "kind": "vehicle", "insured_value": 112500000,
      "vehicle": { "plate": "JKL123", "brand": "…", "line": "…", "model_year": "2023",
                   "color": "…", "engine": "…", "vin_or_chassis": "…",
                   "fasecolda_code": "…", "service": "Particular", "use": "…" } }
  ],
  "coverages": [
    { "name": "Responsabilidad civil extracontractual", "insured_sum": 4000000000,
      "deductible": "10 % mínimo 1 SMMLV", "premium": null }
  ],
  "premium": { "net": 2450000, "issuance_costs": 12000, "vat": 467780,
               "vat_percentage": 19, "other_charges": null, "discounts": null, "total": 2929780 },
  "notes": null
}
```

Reglas de formato:

- `document_type`: `CC`, `CE`, `NIT`, `TI`, `PAS`, `RC`. El documento va solo en dígitos; el NIT sin
  dígito de verificación.
- Persona: `first_name` + `last_name` o `full_name`. Empresa: `business_name`.
- `phones[].kind`: `mobile`, `landline` o `phone`.
- `risks[].kind`: `vehicle`, `person`, `property`, `credit`, `other`. Un inmueble va en
  `property` (`address`, `city`, `construction_type`); una persona asegurada, en `person`.
- `term.kind`: `new` o `renewal` (con `number` = cuál renovación).
- `policy_type: "collective"` crea solo la póliza madre; los certificados no se crean desde PDF.
- Los segmentos que el PDF imprima (`section_code` en Bolívar, `certificate_number`,
  `application_number` en Allianz, `contract_id` en AXA) permiten que la póliza coincida después
  con la del bot. Cópialos si están; no los inventes.
- No hay plan de pagos: las cuotas no se cargan desde un PDF.
- Deja en `null` u omite lo que el PDF no diga. Un dato inventado termina en la cartera y en
  SoftSeguros.

## Lo que no se puede desde el MCP

- Descartar un borrador y «Volver a extraer»: se hacen en la app, en Pólizas › Borradores.
- Ver el PDF junto a los campos: la app tiene esa pantalla de revisión; ofrécela cuando el borrador
  tenga muchos datos dudosos.
- Editar una póliza ya creada.
