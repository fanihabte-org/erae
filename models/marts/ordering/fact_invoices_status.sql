select
    invoice_status_key
    , invoice_id
    , status
    , occurred_at
from {{ ref('inter_invoices_status') }}