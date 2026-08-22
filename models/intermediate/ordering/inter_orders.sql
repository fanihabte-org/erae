with orders_customer_opps as (
    select
          soo.id                   as order_id
        , icu.customer_key
        , iop.opportunity_key
        , soo.order_date
        , soo.status
        , soo.updated_at::date
    from {{ ref('stg_ops_orders') }} soo
    left join {{ ref('inter_customers') }} icu
        on soo.customer_id = icu.customer_id
        and soo.created_at >= icu.valid_from
        and soo.created_at < icu.valid_to
    left join {{ ref('inter_opportunities') }} iop
        on soo.opportunity_id = iop.opportunity_id
        and soo.created_at >= iop.valid_from
        and soo.created_at < iop.valid_to
)

, order_event_dates_pivot as (
    select
        order_id
        , customer_key
        , opportunity_key
        , order_date
        , max(case when status = 'PENDING'   then updated_at end) as processed_at
        , max(case when status = 'SHIPPED'   then updated_at end) as shipped_at
        , max(case when status = 'INVOICED'  then updated_at end) as invoiced_at
        , max(case when status = 'CANCELLED' then updated_at end) as cancelled_at
    from orders_customer_opps
    group by 1, 2, 3, 4
)


, final_order_table as (
    select
        oedp.order_id
        , oedp.customer_key
        , oedp.opportunity_key
        , odd.date_key         as order_date_key
        , pdd.date_key         as processed_date_key
        , sdd.date_key         as shipped_date_key
        , idd.date_key         as invoiced_date_key
        , cdd.date_key         as cancelled_date_key
    from order_event_dates_pivot oedp
    left join {{ ref('inter_dates') }} pdd
        on oedp.processed_at = pdd.full_date
    left join {{ ref('inter_dates') }} sdd
        on oedp.shipped_at = sdd.full_date
    left join {{ ref('inter_dates') }} idd
        on oedp.invoiced_at = idd.full_date
    left join {{ ref('inter_dates') }} cdd
        on oedp.cancelled_at = cdd.full_date
    left join {{ ref('inter_dates') }} odd
        on oedp.order_date = odd.full_date
)

, orders_with_key as (
    select
        {{
            dbt_utils.generate_surrogate_key(
                ['order_id', 'order_date_key'
                ,'processed_date_key' ,'shipped_date_key',
                'invoiced_date_key', 'cancelled_date_key']
            )
        }}                         as order_key
        , order_id
        , customer_key
        , opportunity_key
        , order_date_key
        , processed_date_key
        , shipped_date_key
        , invoiced_date_key
        , cancelled_date_key
    from final_order_table
)

select * from orders_with_key

