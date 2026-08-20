with snapshot_products as (
    select * from {{ ref('products_snapshot') }}
)

select
    dbt_scd_id                         as product_key
    , id                               as product_id
    , name
    , category
    , family
    , price_usd
    , cost_usd
    , is_discontinued = False          as is_active
    , discontinued_on
    , launch_date
    , dbt_valid_from                    as valid_from
    , coalesce(dbt_valid_to,
               '9999-12-31'::timestamp) as valid_to
    , dbt_valid_to is null              as is_current
from snapshot_products