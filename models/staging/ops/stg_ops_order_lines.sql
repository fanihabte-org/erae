with ops_order_line_cleaned as (
    select
        order_line_id::bigint                  as id
        , order_id::bigint
        , product_id::bigint
        , unit_price::decimal(18,2)
        , unit_cost_usd::decimal(18,2)
        , quantity::int
        , discount_pct::decimal(5,2)
        , line_amount::decimal(18,2)
        , created_at::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as created_at
        , updated_at::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as updated_at
        , dw_run_timestamp::timestamp
            at time zone 'America/Los_Angeles'
            at time zone 'UTC'                 as dw_run_timestamp
    from {{ source('operations', 'order_lines') }}
    order by 1, 2, 3
)

select * from ops_order_line_cleaned