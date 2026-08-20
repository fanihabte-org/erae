with order_line as (
    select
        {{
            dbt_utils.generate_surrogate_key(['id', 'updated_at'])
        }}                  as order_item_key
        , id                as order_item_id
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

, earliest_order_key as (
    select
        distinct on(order_id)
          order_id
        , order_key
    from {{ ref('inter_orders') }}
    order by order_id, updated_at asc
)

select
    order_item_key
    , order_item_id
    , eord.order_key   as earliest_order_key
    , ipd.product_key
    , quantity
    , line_amount
    , created_at
from order_line ol
left join earliest_order_key eord
    on eord.order_id = ol.order_id
join {{ ref('inter_products') }} ipd
    on ol.product_id = ipd.product_id
    and ol.created_at >= ipd.valid_from
    and ol.created_at < ipd.valid_to

