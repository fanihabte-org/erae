with orders as (
    select
        {{
            dbt_utils.generate_surrogate_key( ['soo.id', 'soo.updated_at'] )
        }}                         as order_key
        , soo.id                   as order_id
        , soo.customer_id          as customer_key
        , soo.opportunity_id       as opportunity_key
        , soo.sales_channel        as channel_key
        , soo.status               as current_status
        , soo.order_date           as order_date_key
--         , soo.ship_date            as ship_date_key
--         , soo.invoice_date         as invoice_date_key
        , sum(sorl.line_amount)    as total_amount
    from {{ ref('stg_ops_orders') }} soo
    join {{ ref('stg_ops_order_lines') }} sorl
        on sorl.order_id = soo.id
    group by 1,2,3,4,5,6,7
)

select * from orders
