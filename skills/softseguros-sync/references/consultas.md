# Consultas: pólizas, pagos, anexos y certificados

Las ocho tools de consulta son de solo lectura y cualquier miembro de la agencia puede usarlas.

## Contenido

- [Pólizas](#pólizas)
- [Estados de una póliza](#estados-de-una-póliza)
- [El PDF de una póliza](#el-pdf-de-una-póliza)
- [Pagos y cartera](#pagos-y-cartera)
- [Anexos](#anexos)
- [Certificados](#certificados)
- [Consultas frecuentes](#consultas-frecuentes)

## Pólizas

### `search_policies`

| Parámetro | Qué hace de verdad |
| --- | --- |
| `search` | Coincidencia parcial, sin distinguir mayúsculas, en: número de póliza, nombre y documento del tomador, nombre y documento del asegurado, nombre y código del producto, estado tal como lo escribe la aseguradora, etiqueta del riesgo (ahí suele estar la placa) y agrupador. También encuentra pólizas por un riesgo vinculado. Es un solo texto: «perez sura» no encuentra nada, busca «perez» y filtra con `carrier`. |
| `policy_number` | Igualdad exacta con el número guardado. Úsalo solo si lo copiaste de un resultado. |
| `carrier` | Slug exacto (`sura`, `bolivar`, `hdi`, `allianz`, `qualitas`, `axa`, `gnp`, `mapfre`, `chubb`, `zurich`, `liberty`, `estado`, `previsora`, `equidad`, `solidaria`, `sbs`, `reservas`…). |
| `start_date_from` / `start_date_to` | Inicio de vigencia dentro del rango. |
| `end_date_from` / `end_date_to` | Fin de vigencia dentro del rango. Es el filtro para «vencen». |
| `status` | Un solo valor: `active`, `pre_renewal`, `renewed`, `expired`, `not_renewed`, `cancelled`, `pending`, `unknown`. |
| `policy_pdf_status` | `linked`, `pending`, `queued`, `not_found`, `error`. |
| `page`, `limit` | `limit` 20 por defecto, 50 máximo. |

No hay filtro por tipo de póliza (lee `policy_type` en cada fila), por vendedor (lee
`commission_sellers` en cada fila) ni por producto,
y el orden es fijo: inicio de vigencia más
reciente primero. Para «las próximas a vencer» acota con `end_date_from` / `end_date_to` en vez de
pedir muchas páginas.

### Campos útiles de una póliza

| Campo | Significado |
| --- | --- |
| `unique_key` | Para `get_policy` y `download_policy_pdf`. No lo muestres. |
| `id` | Para `link_email` (`object_type: "policy"`). |
| `policy_number`, `carrier_slug`, `product_name`, `product_code` | Cómo nombrarla. |
| `policy_type` | `individual` o `collective` (la colectiva tiene certificados). |
| `holder_name`, `holder_document` | Tomador. |
| `insured_name`, `insured_document` | Asegurado, cuando es otro. |
| `start_date`, `end_date` | Vigencia. |
| `status`, `source_status`, `status_source` | Estado normalizado, el texto de la aseguradora y de dónde salió el estado. |
| `premium`, `financials` (`net_premium`, `vat`, `issuance_costs`), `currency` | Prima total y su desglose. Un componente vacío es «sin dato», no cero. |
| `insured_risk_label`, `insured_risk` | El riesgo: placa y vehículo, dirección, persona. |
| `coverages` | Amparos, cuando se leyeron de un PDF. |
| `has_onerous_beneficiary`, `onerous_beneficiary_name` | Beneficiario oneroso (banco, leasing). |
| `cancellation_date` | Fecha de cancelación, si la hay. |
| `policy_term` | Si es póliza nueva o renovación, y cuál. |
| `previous_cycle_unique_key`, `next_cycle_unique_key` | La vigencia anterior y la siguiente de la misma póliza. Sirven para recorrer renovaciones con `get_policy`. |
| `endorsements` | Anexos que la aseguradora trae dentro de la póliza (por ejemplo Bolívar). |
| `ingestion_origin` | `bot` (la trajo el robot del portal) o `manual_pdf` (se creó desde un PDF). |
| `manual_override_fields` | Campos que un anexo aplicado desde PDF cambió y el bot ya no sobrescribe. |
| `commission_sellers` | Vendedores asignados a la póliza (`sellers` con nombre, `pct`, `base`; `version`). `null`: nadie asignó vendedores. Para verlos o agregarlos: [vendedores.md](vendedores.md). |
| `raw_data` | Lo que mandó la aseguradora, sin normalizar. Último recurso. |

Una misma póliza aparece una vez por vigencia: la de 2025 y su renovación de 2026 son dos filas
con el mismo número y distinta `start_date`. Al responder «¿tiene póliza de autos?», mira la
vigencia actual (`active`, o `pre_renewal` si aún no empieza), no la primera fila.

## Estados de una póliza

| `status` | En palabras de la agencia | Detalle |
| --- | --- | --- |
| `active` | Vigente | Sigue `active` hasta 10 días después de `end_date` (plazo de gracia mientras llega la renovación). Una póliza `active` con `end_date` de la semana pasada no es un error. |
| `pre_renewal` | Renovación que aún no empieza | Ya se emitió y su `start_date` es futura. Pasa a `active` sola el día que empieza. |
| `renewed` | Ya renovada | Esa vigencia tiene sucesora (`next_cycle_unique_key`). |
| `expired` | Vencida | Pasó el plazo de gracia sin renovación. |
| `not_renewed` | No renovada | La aseguradora la reportó así. |
| `cancelled` | Cancelada | Mira `cancellation_date`. |
| `pending` | Pendiente | En trámite según la aseguradora. |
| `unknown` | Sin estado claro | Mira `source_status`. |

«Pólizas por renovar» son las `active` cuyo `end_date` cae en el rango. Las que ya tienen
renovación emitida salen como `renewed` (la vieja) y `pre_renewal` (la nueva): no las cuentes como
pendientes de renovar.

## El PDF de una póliza

`download_policy_pdf(unique_key)` funciona cuando `policy_pdf_status` es `linked`, tanto si el PDF
lo bajó el bot como si la póliza se creó desde un PDF. Antes de descargar mira `policy_pdf_status` en la póliza:

| `policy_pdf_status` | Qué decir |
| --- | --- |
| `linked` | Se puede descargar. |
| `pending`, `queued` | La descarga automática está en cola; todavía no hay PDF. |
| `not_found` | El portal de la aseguradora no tiene PDF para esa póliza. |
| `error` | La descarga falló (`policy_pdf_last_error`). |
| vacío | Esa aseguradora no tiene descarga automática de PDF. Busca en Archivos con `search_files`. |

Si responde que el PDF no está vinculado, es uno de los casos de la tabla. Si responde que el
archivo no está en el almacenamiento, la póliza apunta a un archivo que ya no existe: pídele a la
persona que lo reporte a soporte.

## Pagos y cartera

Un «pago» aquí es un registro de cartera que la aseguradora reporta: una cuota o recibo con su
saldo y su mora. No es un cobro hecho en el CRM.

### `search_payments`

| Parámetro | Qué hace de verdad |
| --- | --- |
| `search` | Parcial en: número de póliza, referencia de pago, número de factura, nombre y documento del pagador, producto. |
| `policy_number` | Exacto. |
| `carrier` | Slug exacto. |
| `due_date_from` / `due_date_to` | Fecha de vencimiento del pago. |
| `status` | Texto exacto tal como lo guarda cada aseguradora («Pendiente» en HDI, otros textos en las demás). No hay lista cerrada: busca primero sin `status`, mira qué valores aparecen y filtra después. |

Campos útiles: `amount` (valor), `balance` (saldo), `currency`, `due_date`, `last_payment_date`,
`days_overdue`, `aging_bucket_label` y `mora_label` (edad de la cartera), `installment_number` /
`installment_total` (cuota N de M), `payment_method`, `is_financed`, `has_payment_agreement`,
`has_automatic_debit`, `payer_name`, `payer_document`, `canonical_status` (`pending` o
`cancelled`, el único estado normalizado; no se puede filtrar por él).

Para cartera vencida: `due_date_to` = ayer y revisa `balance` y `days_overdue`. No todas las
aseguradoras reportan cartera; si una no devuelve pagos, dilo así en vez de «está al día».
No sumes valores de monedas distintas.

## Anexos

Un anexo (endoso) es un movimiento sobre una póliza: cambio de valor asegurado, inclusión de
beneficiario, prórroga, cancelación.

`search_endorsements` filtra por `carrier`, `policy_number` (exacto) y `search` (parcial en número
de póliza, número de anexo, tipo de anexo y estado de la aseguradora). No tiene filtro de fechas y
ordena por fecha de registro, más reciente primero.

Campos: `endorsement_number`, `endorsement_type`, `issue_date`, `effective_date`, `end_date`,
`premium`, `status`, `policy_number`, `policy_unique_key` (la póliza a la que pertenece: pásalo a
`get_policy`). Un anexo aplicado desde un PDF trae `raw_data.origin = "manual_pdf"`.

Para «los anexos de la póliza X»: busca la póliza, copia su `policy_number` exacto y pásalo a
`search_endorsements`. Algunas aseguradoras traen los anexos solo dentro de la póliza
(`endorsements` en `get_policy`); si la búsqueda sale vacía, mira ahí antes de decir que no tiene.

## Certificados

Un certificado es cada asegurado o riesgo dentro de una póliza colectiva (un vehículo de una
flota, un afiliado de un grupo).

`search_certificates` filtra por `carrier`, `certificate_number` (exacto), fechas de vigencia
(`start_date_*`, `end_date_*`) y `search` (parcial en número de certificado, nombre y documento del
asegurado, referencia de la póliza madre, estado de la aseguradora y etiqueta del riesgo).

Campos: `certificate_number`, `insured_name`, `insured_document`, `insured_risk_label`,
`start_date`, `end_date`, `premium`, `status`, `parent_policy_reference` (número de la póliza
madre), `master_policy_unique_key` (pásalo a `get_policy`).

Para «los certificados de la colectiva X»: `search` con el número de la póliza madre. No hay
filtro por estado: léelo en cada fila.

## Consultas frecuentes

**«¿Qué pólizas vencen esta semana?»**
`search_policies(end_date_from=<lunes>, end_date_to=<domingo>, status="active")`. Di el rango y el
total. Si la persona quiere también las que ya se renovaron, repite con `status="renewed"`.

**«Pólizas de Juan Pérez» / «de la cédula 1012345678» / «de la placa JKL123»**
`search_policies(search="1012345678")`. El documento es más fiable que el nombre. Agrupa por
número de póliza y muestra la vigencia actual de cada una.

**«¿Llegó la renovación de la póliza 123456?»**
`search_policies(search="123456")`. Si hay una fila `pre_renewal` o una `active` con `start_date`
reciente, llegó. Si solo hay una `active` por vencer o una `expired`, todavía no.

**«¿Cuánto debe este cliente?»**
`search_payments(search=<documento>)`, suma `balance` por moneda y separa lo vencido
(`days_overdue` mayor que 0).

**«Pásame el PDF de la póliza X»**
Busca la póliza, revisa `policy_pdf_status`, descarga con `download_policy_pdf` y entrega el
archivo. Si no hay PDF vinculado, prueba `search_files(query=<número>, mime_type="application/pdf")`.

**«¿Cuántas pólizas tengo en SURA?»**
`search_policies(carrier="sura", limit=1)` y lee `total`. No hace falta traer las filas. Es el
total de vigencias, no de pólizas distintas; acláralo, o filtra `status="active"`.
