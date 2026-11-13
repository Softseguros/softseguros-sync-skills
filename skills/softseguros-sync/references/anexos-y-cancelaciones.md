# Anexos, prórrogas y cancelaciones desde un PDF

No todo PDF que llega es una póliza nueva. El mismo flujo de borradores
([crear-poliza-desde-pdf.md](crear-poliza-desde-pdf.md)) reconoce qué es el documento y, cuando es
un anexo o una cancelación de una póliza que ya está en la cartera, **lo aplica a esa póliza** en
vez de crear otra.

## Qué es el PDF: `document_class`

| `document_class` | Qué es | Qué pasa al confirmar |
| --- | --- | --- |
| `policy` | Una póliza o su renovación | Se crea la póliza. |
| `endorsement` | Un anexo: cambio de prima, beneficiario oneroso, prórroga | Se registra el anexo y se aplican a la póliza los cambios elegidos. |
| `cancellation` | Una cancelación | Se registra y la póliza queda cancelada. |
| `other` | Nota crédito, recibo, carátula, otro | Solo se puede vincular el PDF a su póliza. |

El servidor lo decide con las señales del documento (`document_signals`: título, operación, número
de anexo). Si se equivocó, y la persona lo confirma, corrígelo con
`update_policy_draft(document_class=…)`; el borrador se vuelve a validar.

`parent_policy` es la póliza de la cartera a la que pertenece el documento (número, estado,
vigencia, `policy_type`). Si viene vacío, esa póliza todavía no está en el Sincronizador.

## Si la póliza del anexo no está: `waiting_policy`

Un anexo o una cancelación sin su póliza queda en `waiting_policy`, sin límite de tiempo. No se
puede aplicar ni convertir en póliza. Explícale a la persona las dos salidas:

- Esperar: cuando la póliza llegue (por el bot o porque alguien la cree desde su PDF), el borrador
  pasa solo a «listo para revisar» y entonces se aplica.
- Crear primero la póliza desde su propio PDF, si lo tiene.

Mientras tanto se puede editar y se descarta desde la app. `list_policy_drafts` lo muestra entre
los abiertos.

## El plan: `endorsement_plan`

Con su póliza en la cartera, el borrador trae un plan con lo que el documento cambiaría:

| `changes[].kind` | Cambio |
| --- | --- |
| `premium` | La prima del anexo, sumada a la de la póliza o reemplazándola. |
| `onerous_beneficiary` | Agrega un beneficiario oneroso (banco, leasing). |
| `onerous_beneficiary_removal` | Lo quita. |
| `extension` | Prórroga: nueva fecha de fin. Reactiva una póliza que había vencido por fecha. |
| `cancellation` | La póliza queda `cancelled` con su fecha de cancelación. |

Cada cambio trae el valor actual de la póliza y el que quedaría. Muéstraselos a la persona como
«hoy → queda», uno por línea, antes de confirmar.

### La prima

El cambio `premium` trae, para el total y para cada componente (neta, IVA, gastos de expedición),
el valor actual, el del anexo y el resultado de cada modo:

- `premium_mode: "add"` (por defecto): la prima del anexo se **suma** a la de la póliza. Es lo
  normal en un anexo que cobra o devuelve una diferencia.
- `premium_mode: "replace"`: la prima del anexo **reemplaza** la de la póliza. Para un documento
  que reexpide la póliza con su prima completa.

Solo valen los modos de `available_modes`. Pedir otro responde que ese modo no está disponible y
nombra el componente que le falta al anexo. Un valor propuesto en `null` significa que ese
componente no se toca en ese modo; no lo leas como cero. Si un modo dejaría algún valor por debajo
de cero, la confirmación se rechaza (`NEGATIVE_PREMIUM`): casi siempre el modo correcto es el otro
o la prima del anexo se leyó mal.

Pregunta a la persona cuál modo aplica cuando haya dos disponibles y no sea evidente; no lo decidas
por ella.

### Avisos del plan

| Código | Qué significa y qué decir |
| --- | --- |
| `IS_ENDORSEMENT`, `IS_CANCELLATION` | Informativos: el PDF es un anexo o una cancelación de la póliza N. |
| `MULTI_RISK_ENDORSEMENT` | El anexo afecta varios riesgos, o un certificado de una colectiva. No se propone ningún cambio: solo se puede registrar. |
| `PREMIUM_BREAKDOWN_MISSING` | Falta un componente de la prima para poder aplicarla (el aviso dice cuál). Corrígelo en el borrador o registra el anexo sin aplicar la prima. |
| `ENDORSEMENT_ALREADY_APPLIED` | Ese anexo ya está aplicado (`endorsement_plan.already_applied`). Confirmar solo vincula el PDF. |
| `COLLECTIVE_CANCELLATION` | Es una póliza colectiva: cancelarla cancela la póliza madre con todos sus certificados. |
| `FUTURE_CANCELLATION` | La cancelación rige desde una fecha futura, pero la póliza queda cancelada desde hoy. |
| `PARENT_POLICY_MISSING` | La póliza del documento no está en la cartera (ver `waiting_policy`). |
| `IS_OTHER_DOCUMENT` | No es póliza ni anexo: solo se puede vincular. |

## Confirmar

`confirm_policy_draft(draft_id, expected_revision, apply_changes, premium_mode)`

| `apply_changes` | Efecto |
| --- | --- |
| omitido | Aplica todos los cambios del plan. |
| lista de `kind` | Aplica solo esos (`["premium", "extension"]`). |
| `[]` | Solo registra el anexo y vincula el PDF; la póliza no cambia. |

Para un documento `other` con su póliza: `duplicate_resolution: "link_pdf"`.

El borrador termina en `applied_to_policy` y `result.unique_key` es la póliza. El anexo queda en
`search_endorsements` y el PDF en Archivos.

### Antes de confirmar

Aplicar un anexo o una cancelación **no se puede deshacer desde el Sincronizador**, y el bot no
revierte esos valores cuando vuelve a traer la póliza. Por eso:

1. Muestra el plan completo: qué póliza, qué cambia de qué valor a cuál, con qué modo de prima.
2. Para una cancelación pide una confirmación que la nombre («sí, cancela la póliza 123456»), no un
   «ok» genérico. Si es colectiva, di antes que se cancelan todos sus certificados.
3. Usa la `revision` del borrador que acabas de mostrar.

### Si la póliza cambió mientras tanto

Si la confirmación responde «La póliza cambió mientras revisabas el anexo», el bot actualizó la
póliza entre el momento en que se calculó el plan y la confirmación. No se aplicó nada. Llama
`get_policy_draft`, muestra a la persona el plan recalculado y confirma con la nueva `revision`
solo si sigue de acuerdo.

## Qué queda después

- La póliza muestra los valores nuevos y `manual_override_fields` lista los campos que el anexo
  cambió. El bot ya no los sobrescribe.
- Una cancelación deja `status: "cancelled"` y `cancellation_date`.
- La póliza se marca para volver a sincronizarse con SoftSeguros.
- Si después llega otro borrador del mismo PDF, el plan dirá que ya está aplicado.
