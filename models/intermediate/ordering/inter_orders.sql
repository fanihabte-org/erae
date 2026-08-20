with orders as (
    select
        {{
            dbt_utils.generate_surrogate_key( ['soo.id', 'soo.updated_at'] )
        }}                         as order_key
        , soo.id                   as order_id
        , icu.customer_key
        , iop.opportunity_key
        , idts.date_key            as order_date_key
        , soo.status
        , updated_at
    from {{ ref('stg_ops_orders') }} soo
    left join {{ ref('inter_customers') }} icu
        on soo.customer_id = icu.customer_id
        and soo.created_at >= icu.valid_from
        and soo.created_at < icu.valid_to
    join {{ ref('inter_opportunities') }} iop
        on soo.opportunity_id = iop.opportunity_id
        and soo.created_at >= iop.valid_from
        and soo.created_at < iop.valid_to
    join {{ ref('inter_dates') }} idts
        on soo.order_date = idts.full_date
)

select * from orders
