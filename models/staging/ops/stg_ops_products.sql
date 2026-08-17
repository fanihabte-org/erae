with ops_products_cleaned as (
    select
        product_id::bigint                     as id
        , trim(upper(sku))                     as sku
        , trim(upper(product_name))            as name
        , trim(upper(category))                as category
        , trim(upper(product_family))          as family
        , list_price_usd::decimal(18,2)        as price_usd
        , standard_cost_usd::decimal(18,2)     as cost_usd
        , is_discontinued::boolean
        , discontinued_on::date
        , launch_date::date
        , created_at::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as created_at
        , updated_at::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as updated_at
        , dw_run_timestamp::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as dw_run_timestamp
    from {{ source('operations', 'products') }}
    order by 1, 2, 3
)

select * from ops_products_cleaned