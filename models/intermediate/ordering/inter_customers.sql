with snapshot_customers as (
    select * from {{ ref('customers_snapshot') }}
)

select
    dbt_scd_id            as customer_key
    , id                  as customer_id
    , name
    , segment
    , industry
    , region
    , employee_count
    , credit_limit_usd
    , is_active
    , dbt_valid_to        as valid_to
    , dbt_valid_from      as valid_from
    , case
        when dbt_valid_to is null
        then true else false end   as is_current
from snapshot_customers