select
    {{
        dbt_utils.generate_surrogate_key (
            ['id', 'status', 'updated_at']
        )
    }}             as order_status_key
    , id           as order_id
    , status
    , updated_at
from {{ ref('stg_ops_orders') }}