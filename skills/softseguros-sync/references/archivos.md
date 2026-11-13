# Archivos

«Archivos» es el repositorio de documentos de la agencia: los PDF que bajaron los bots, los
adjuntos que llegaron por correo y lo que alguien subió a mano. Cada archivo se clasifica y puede
estar vinculado a una póliza, un certificado, un anexo, un contacto o una empresa.

`search_files` y `download_file` son de lectura y cualquier miembro puede usarlas, con una
excepción: los archivos que llegaron por correo siguen el acceso del buzón. Quien no lee ese
buzón no los ve en la lista, y pedirlos por id responde «File not found».

## `search_files`

| Parámetro | Valores |
| --- | --- |
| `query` | Coincidencia parcial en el nombre del archivo o en el asunto del correo del que vino. No busca dentro del contenido. |
| `mime_type` | Tipo exacto: `application/pdf`, `image/jpeg`… |
| `status` | `received` (recién llegado), `processing` (leyéndose), `needs_review` (hay que revisar su clasificación o vínculo), `ready` (clasificado, sin vincular), `linked` (vinculado a un objeto), `pending_link` (se desvinculó y espera vínculo), `failed`, `discarded`. |
| `source_type` | `bot`, `email`, `manual`. |
| `document_type` | `policy_declarations` (carátula), `policy_contract` (clausulado), `policy_individual`, `policy_collective`, `certificate`, `endorsement` (anexo), `invoice`, `payment_receipt`, `id_document`, `vehicle_registration` (tarjeta de propiedad), `other`, `unknown`. |
| `page`, `limit` | 20 por defecto, 50 máximo. |

Cada fila: `id` (el `file_id`), `filename`, `content_type`, `size_bytes`, `created_at`, `status`,
`source_type`, `document_type` y `primary_link` (el objeto al que está vinculado, si lo está).

Consejos:

- Para el PDF de una póliza busca por su número: los bots suelen nombrar el archivo con él. Si no
  aparece, prueba el documento o el nombre del tomador, o filtra por `document_type`.
- `document_type` es una clasificación automática: un archivo `unknown` u `other` puede ser justo
  el que se busca. No lo excluyas si la búsqueda por nombre lo trae.
- Mira `size_bytes` antes de descargar.

## `download_file(file_id)`

Devuelve `filename`, `content_type`, `size` y `content_base64` con el archivo completo. Un archivo
grande llena el contexto: mira `size_bytes` antes. Descárgalo cuando la persona quiera el archivo
o haga falta leerlo; para confirmar que existe o a qué está vinculado basta `search_files`.

## Archivos y pólizas

- Crear una póliza desde un PDF de Archivos: `create_policy_draft_from_file(file_id)`. Sirve
  cualquier PDF que no esté descartado, aunque ya esté vinculado; el borrador avisa si la póliza ya
  existe.
- `download_policy_pdf` entrega el PDF de una póliza tanto si lo bajó el bot como si la póliza se
  creó desde un PDF, así que para «el PDF de la póliza X» úsala primero y deja `search_files` como
  respaldo.
- Este MCP no sube archivos sueltos, no cambia su clasificación ni los vincula o descarta. Eso se
  hace en la pantalla Archivos.
