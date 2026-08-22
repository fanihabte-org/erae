select
    invoice_key
    , invoice_number
    , order_key
    , issue_date_key
    , voided_date_key
    , currency_iso_code
    , amount
from {{ ref('inter_invoices') }}