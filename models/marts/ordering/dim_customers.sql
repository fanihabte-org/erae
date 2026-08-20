select
    customer_key
    , customer_id
    , name
    , segment
    , industry
    , region
    , employee_count
    , credit_limit_usd
    , is_active
    , valid_to
    , valid_from
    , is_current
from {{ ref('inter_customers') }}