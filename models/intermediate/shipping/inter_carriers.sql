with snapshot_carriers as (
    select * from {{ ref('carriers_snapshot') }}
)

select
    dbt_scd_id                          as carrier_key
    , id                                as carrier_id
    , name
    , mode
    , cost_index
    , published_otd_rate                as otd_rate
    , dbt_valid_from                    as valid_from
    , coalesce(dbt_valid_to,
               '9999-12-31'::timestamp) as valid_to
    , dbt_valid_to is null              as is_current
from snapshot_carriers