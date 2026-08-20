select
    {{
        dbt_utils.generate_surrogate_key(['order_key', 'status'])
    }}             as status_event_key
    , order_key
    , status
    , updated_at   as changed_at
from {{ ref('inter_orders') }}