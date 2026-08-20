with order_line as (
    select
        id
        , order_id
        , product_id
        , quantity
        , unit_price
        , discount_pct
        , line_amount
        , created_at
        , updated_at
        , dw_run_timestamp
    from {{ ref('stg_ops_order_lines') }}
)

select * from order_line