{{
    config(
        indexs = [
            {
                'columns': ['order_key', 'order_date_key', 'shipped_date_key'],
                'type': 'btree'
            }
        ]
    )
}}

with inter_orders as (
    select
        order_key
        , order_id
        , customer_key
        , opportunity_key
        , order_date_key
        , processed_date_key
        , shipped_date_key
        , invoiced_date_key
        , cancelled_date_key
    from {{ ref('inter_orders') }}
)

, current_order_status as (
    select
        distinct on(order_id)
          order_id
        , order_status_key
    from {{ ref('inter_order_status') }}
    order by order_id, updated_at desc
)

select
    io.order_key
    , io.order_id
    , io.customer_key
    , io.opportunity_key
    , cos.order_status_key   as cur_status_key
    , io.order_date_key
    , io.processed_date_key
    , io.shipped_date_key
    , io.invoiced_date_key
    , io.cancelled_date_key
from inter_orders io
left join current_order_status cos
    on io.order_id = cos.order_id
