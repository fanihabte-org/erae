select
    status_event_key
    , order_key
    , status
    , changed_at
from {{ ref('inter_order_status') }}