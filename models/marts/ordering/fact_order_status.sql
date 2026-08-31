select
    order_status_key
    , order_id
    , status
    , occurred_at
from {{ ref('inter_order_status') }}