with snapshot_warehouses as (
    select * from {{ ref('warehouses_snapshot') }}
)

select
    dbt_scd_id                          as warehouse_key
    , id                                as warehouse_id
    , name
    , region
    , latitude
    , longitude
    , dbt_valid_from                    as valid_from
    , coalesce(dbt_valid_to,
               '9999-12-31'::timestamp) as valid_to
    , dbt_valid_to is null              as is_current
from snapshot_warehouses