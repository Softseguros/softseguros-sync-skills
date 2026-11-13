# Tools del MCP «Softseguros Sync» (`/mcp`)

Nombre, parámetros y descripción de cada tool, tal como el servidor los entrega al modelo.
Generado con `scripts/render_tool_catalog.py`; no se edita a mano.

## `search_certificates(carrier: Optional[str] = None, search: Optional[str] = None, certificate_number: Optional[str] = None, start_date_from: Optional[str] = None, start_date_to: Optional[str] = None, end_date_from: Optional[str] = None, end_date_to: Optional[str] = None, page: int = 1, limit: int = 20)`

[Insurance Sync] Search the agency's normalized certificates: each insured or risk
inside a collective policy (limit default 20, max 50).

search: partial, case-insensitive match on the certificate number, insured name or
document, the master policy reference, the carrier's own status text and the risk label.
To list the certificates of a collective policy, search its policy number.
certificate_number: exact match. carrier: the exact carrier slug in lowercase.
Date filters are YYYY-MM-DD (inclusive UTC day bounds). For expiry / "vencen",
use end_date_from / end_date_to (e.g. ISO week 2026-07-20 .. 2026-07-26).
Each row carries master_policy_unique_key (pass it to get_policy).

## `get_certificate(unique_key: str)`

[Insurance Sync] Get one normalized certificate of the agency by its unique_key
(opaque: copy it from a search_certificates row).

## `search_endorsements(carrier: Optional[str] = None, search: Optional[str] = None, policy_number: Optional[str] = None, page: int = 1, limit: int = 20)`

[Insurance Sync] Search the agency's normalized endorsements (anexos), newest record
first (limit default 20, max 50).

search: partial, case-insensitive match on the policy number, endorsement number,
endorsement type and the carrier's own status text.
policy_number: exact match. carrier: the exact carrier slug in lowercase.
There is no date filter. Each row carries policy_unique_key (pass it to get_policy).
Some carriers only bring endorsements inside the policy (its endorsements field).

## `get_endorsement(unique_key: str)`

[Insurance Sync] Get one normalized endorsement of the agency by its unique_key
(opaque: copy it from a search_endorsements row).

## `search_files(query: Optional[str] = None, mime_type: Optional[str] = None, status: Optional[str] = None, source_type: Optional[str] = None, document_type: Optional[str] = None, page: int = 1, limit: int = 20)`

[Insurance Sync] Search the agency's files (Archivos) (limit default 20, max 50).

query: case-insensitive match on filename / email subject (not on the file's content).
mime_type: exact content_type filter (e.g. application/pdf).
status: received|processing|needs_review|ready|linked|pending_link|failed|discarded.
source_type: bot|email|manual.
document_type: policy_declarations|policy_contract|policy_individual|policy_collective|
certificate|endorsement|invoice|id_document|payment_receipt|vehicle_registration|other|unknown.
Files that came from email are only listed for the mailboxes the person reads.
Does not return file content — use download_file with an id. To create a policy from a
PDF listed here, pass its id to create_policy_draft_from_file.

## `download_file(file_id: str)`

[Insurance Sync] Download one of the agency's files by id (base64-encoded).

Use search_files to find ids. The whole file comes back in content_base64, with no size
limit: check size_bytes in search_files first.

## `search_payments(carrier: Optional[str] = None, search: Optional[str] = None, policy_number: Optional[str] = None, due_date_from: Optional[str] = None, due_date_to: Optional[str] = None, status: Optional[str] = None, page: int = 1, limit: int = 20)`

[Insurance Sync] Search the agency's normalized payments: the portfolio (cartera) each
carrier reports, one row per installment or receipt (limit default 20, max 50).

search: partial, case-insensitive match on the policy number, payment reference, invoice
number, payer name or document, and product name or code.
policy_number: exact match. carrier: the exact carrier slug in lowercase.
Date filters are YYYY-MM-DD (inclusive UTC day bounds). For due / "vencen",
use due_date_from / due_date_to. status is an exact-match free string as stored
by the carrier (e.g. Pendiente for HDI); not a closed enum: search without it first to
see the values in use. Rows carry amount, balance, days_overdue and raw_data.

## `get_payment(unique_key: str)`

[Insurance Sync] Get one normalized payment of the agency by its unique_key
(opaque: copy it from a search_payments row).

## `search_policies(carrier: Optional[str] = None, search: Optional[str] = None, policy_number: Optional[str] = None, start_date_from: Optional[str] = None, start_date_to: Optional[str] = None, end_date_from: Optional[str] = None, end_date_to: Optional[str] = None, status: Optional[PolicyStatus] = None, policy_pdf_status: Optional[PolicyPdfStatus] = None, page: int = 1, limit: int = 20)`

[Insurance Sync] Search the agency's normalized policies, newest start date first
(limit default 20, max 50). One row per coverage period: a renewal is another row.

search: partial, case-insensitive match on the policy number, holder and insured name or
document, product name or code, the carrier's own status text, the risk label (e.g. a plate)
and the grouper. One text, not several words for several fields.
policy_number: exact match with the stored number; use search when the format may differ.
carrier: the exact carrier slug in lowercase (sura, bolivar, hdi, allianz…), not its name.
Date filters are YYYY-MM-DD and correspond to the coverage window (vigencia):
start_date_* = vigencia inicio, end_date_* = vigencia fin (e.g. end_date_from/end_date_to for ISO week 2026-07-20 .. 2026-07-26).
status (one value): active|pre_renewal|renewed|expired|not_renewed|cancelled|pending|unknown.
pre_renewal is an issued renewal that has not started; renewed is a period that already has
a successor; active lasts until 10 days after the end date.
policy_pdf_status: pending|queued|linked|not_found|error — filter by linked PDF state.
There is no filter by policy type: read policy_type (individual|collective) in each row.
Rows carry raw_data (what the carrier sent) and are large: ask for the limit you need.
unique_key (for get_policy / download_policy_pdf) is opaque: copy it from a row.

## `get_policy(unique_key: str)`

[Insurance Sync] Get one normalized policy of the agency by its unique_key.

unique_key is opaque: copy it from a search_policies row (or from previous_cycle_unique_key /
next_cycle_unique_key of another period of the same policy); never build it from the number.

## `download_policy_pdf(unique_key: str)`

[Insurance Sync] Download the PDF linked to a normalized policy (base64-encoded).

Works when the policy has policy_pdf_status=linked, whether a bot downloaded the PDF or the
policy was created from a PDF. Any other state answers that the PDF is not linked (the
message carries the status). Use search_policies(policy_pdf_status='linked') to find
downloadable policies. The whole file comes back in content_base64.
