select
    order_status_key
    , order_id
    , status
    , updated_at
from {{ ref('inter_order_status') }}