select
    {{ dbt_utils.generate_surrogate_key(['id', 'updated_at', 'status']) }}  as status_event_key
    , status
    , id         as order_id
    , updated_at
from {{ ref('stg_ops_orders') }}