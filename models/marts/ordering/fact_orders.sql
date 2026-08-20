with inter_orders as (
    select
        order_key
        , order_id
        , customer_key
        , opportunity_key
        , order_date_key
        , status
        , updated_at
    from {{ ref('inter_orders') }}
)

, current_order_status as (
    select
        distinct on(order_id)
          order_id
        , order_key
        , status   as current_status
    from inter_orders
    order by order_id, updated_at desc
)

select
    io.order_key
    , io.order_id
    , io.customer_key
    , io.opportunity_key
    , io.order_date_key
    , crs.current_status
    , max(case when io.status = 'PENDING'   then io.updated_at end) as processed_at
    , max(case when io.status = 'SHIPPED'   then io.updated_at end) as shipped_at
    , max(case when io.status = 'INVOICED'  then io.updated_at end) as invoiced_at
    , max(case when io.status = 'CANCELLED' then io.updated_at end) as cancelled_at
from inter_orders io
join current_order_status crs
    on io.order_key = crs.order_key
group by 1,2,3,4,5,6
